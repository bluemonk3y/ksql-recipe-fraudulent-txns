#Fraud detection

A simple KSQL recipe that detects when an unexpected txn occurs against a known suspicious recipient that is 'new' to the user account. The idea being that fraudsters will be trying to blend their transactiosn into the account in order to go un-noticed. They will use a well known set of companies in the hope that you already transact with them.

The list of suspicious names is: verizon, alcatel, best buy

To run this recipe:

1. Start Confluent platform (including KSQL)
> bin/confluent start

2. load the suspicious names as a Table
> $ ./load-suspicious-accounts.sh

3. load the valid names as a Table
> $ ./load-valid-accounts.sh


4. Put a KSQL table over both
> KSQL> CREATE TABLE suspicious_accounts (company_name varchar, company_id int) with (key='company_name', kafka_topic = 'suspicious-accounts-json', value_format = 'json');

> KSQL> CREATE TABLE valid_accounts (key varchar, company_name varchar, company_id int) with (key='company_name', kafka_topic = 'valid-accounts-json', value_format = 'json');

4.5 View the table data in KSQL **(remember "set auto.offset.reset = earliest";)**
> KSQL> select * from suspicious_names;

5. Populate the txns topic with good and bad txns. You will see that 'bad-txns' uses the names from the suspicious-accounts.json file - against which it will join
> $ ./write-good-transactions.sh
>  ...
> ^C

> $ ./write-bad-transactions.sh
> ...
> ^C

5.5 Check we have data in the topics
> KSQL> print 'txns-1' FROM BEGINING;


6. Create a stream for user transactions
> KSQL> CREATE STREAM txns (txn_id long, username varchar, recipient varchar, amount double) with (kafka_topic = 'txns-1', value_format = 'json');

6.5 Check that data is available **(remember "set auto.offset.reset = earliest";)**
> KSQL> SELECT * from txns;

7. Join the stream with suspicious-accounts to identify potential threats - **note the composite key - we need this for the join**
> KSQL> CREATE STREAM suspicious_txns AS SELECT **username + '-' + recipient as sus_key**, txn_id, username, amount, recipient, company_name as sus_company_name FROM txns LEFT JOIN suspicious_accounts ON txns.recipient = suspicious_accounts.company_name WHERE company_name is not null;

8. Check against the valid-txns using a join (we need that key 'sus_key' now!)
> KSQL> CREATE STREAM still_invalid_txns AS SELECT key, sus_key, username, txn_id, amount, sus_company_name, company_name FROM suspicious_txns LEFT JOIN valid_accounts ON suspicious_txns.sus_key = valid_accounts.key where key is null;


9. Now use a window to determine when the breach occurs (i.e. > 1 in the window)
> CREATE TABLE fraud_event AS SELECT username, COUNT(*) AS txn_count FROM still_invalid_txns WINDOW TUMBLING (size 24 hours) GROUP BY username HAVING COUNT(*) > 1;

Note: you can use a regular kafka_consumer to detect events on the underlying topic: 'suspicious_events'

#Enrich Streams with static JSON file loaded as a TABLE

1. load the valid names as a Table
> $ ./load-valid-accounts.sh

123:{"key": "1234", "username":"alan jones", "created_date":"2017-09-15 09:08:38"}
124:{"key": "1234", "username":"bruce wayne", "created_date":"2017-09-15 09:08:38"}

2) Load the file into a Kafka topic using a bash script.

**!/usr/bin/env bash**
$CONFLUENT_HOME/bin/kafka-console-producer --broker-list localhost:9092 --topic accounts-json --property "parse.key=true" --property "key.separator=:" < resources/valid-accounts.json

3) Create  KSQL table over the topic valid-accounts-json

CREATE TABLE valid_accounts (key long, username varchar, created_date varchar) with (key=key, kafka_topic = 'accounts-json', value_format = 'json');

4) Create a KSQL Stream called ‘txns’ on top of the kafka topic ‘txns-1’

CREATE STREAM txns (txn_id long, userid long long, recipient long, amount double) with (kafka_topic = 'txns-1', value_format = 'json');

4.5) Run the txns generator
> $ ./write-good-transactions.sh

5) Join the ‘txns’ stream with the valid-account stream to create an enriched_txns

> KSQL> CREATE STREAM enriched_txns AS SELECT txn_id, userid, username, recipient FROM txns LEFT JOIN accounts-json ON txns.user_id = accounts-json.key WHERE company_name is not null;

6) For a complete solution see: https://github.com/bluemonk3y/ksql-recipe-fraudulent-txns