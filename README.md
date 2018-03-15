A simple KSQL recipe that detects when an unexpected txn occurs against a known suspicious recipient that is 'new' to the user account. The idea being that fraudsters will be trying to blend their transactiosn into the account in order to go un-noticed. They will use a well known set of companies in the hope that you already transact with them.

The list of suspicious names is: verizon, alcatel, best buy

To run this recipe:

1. Start Confluent platform (including KSQL)
> bin/confluent start

2. load the suspicious names as a Table
> $ ./load-suspicious-names.sh

This will populate the topic 'suspicious-names-json'

3. Put a KSQL table over the top of the topic (from the fraudulent-txns.sql)
> KSQL> CREATE TABLE suspicious_names (company_name varchar, company_id int) with (key='company_name', kafka_topic = 'suspicious-names-json', value_format = 'json');

3.5 View the table data in KSQL **(remember "set auto.offset.reset = earliest";)**
> KSQL> select * from suspicious_names;

4. Populate the txns topic with good and bad txns. You will see that 'bad-txns' uses the names from the suspicious-names.json file - against which it will join
> $ ./write-good-transactions.sh
>
> ^C

> $ ./write-bad-transactions.sh
>
> ^C

4.5 Check we have data in the topics
> KSQL> print 'txns-1' FROM BEGINING;



5. Create a stream for user transactions
> KSQL> CREATE STREAM txns (id long, username varchar, recipient varchar, amount double) with (kafka_topic = 'txns-1', value_format = 'json');

5.5 Check there is data available (remember "set auto.offset.reset = earliest";)
> KSQL> SELECT * from txns;

6. Join the stream with suspicious-names to identify potential threats
> KSQL> CREATE STREAM suspicious_txns AS SELECT username, id as txn_id, amount, recipient, company_name FROM txns LEFT JOIN suspicious_names ON txns.recipient = suspicious_names.company_name WHERE company_name is not null;


7. Now use a window to determine when the breach occurs (i.e. > 1 in the window)
> KSQL> CREATE TABLE suspicious_events AS SELECT username as user_id, COUNT(*) AS txn_count FROM suspicious_txns WINDOW TUMBLING (size 24 hours) GROUP BY name HAVING COUNT(*) > 1;;