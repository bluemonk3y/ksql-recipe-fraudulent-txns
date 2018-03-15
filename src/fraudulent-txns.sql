
--1. run the load-suspicious-names.sh to populate the topic 'suspicious-names-json' topic
CREATE TABLE suspicious_names (company_name varchar, company_id int) with (key='company_name', kafka_topic = 'suspicious-names-json', value_format = 'json');

-- 2. create a stream for user transactions
CREATE STREAM txns (id long, username varchar, recipient varchar, amount double) with (kafka_topic = 'txns-1', value_format = 'json');

-- 3. join the stream with suspicious-names to identify potential threats
-- note: the join will work emmit an event event when it failed to join - to prevent the event we use an 'is not null filter'
--SELECT name, id as txn_id, amount, recipient, company_name FROM txns LEFT JOIN suspicious_names ON txns.recipient = suspicious_names.company_name where company_name is not null;
--ISSUE  why is the txn_id null?
CREATE STREAM suspicious_txns AS SELECT username, id as txn_id, amount, recipient, company_name FROM txns LEFT JOIN suspicious_names ON txns.recipient = suspicious_names.company_name WHERE company_name is not null;

-- 4. now use a window to determine when the breach occurs (i.e. > 1 in the window)
CREATE TABLE suspicious_events AS SELECT username as user_id, COUNT(*) AS txn_count FROM suspicious_txns WINDOW TUMBLING (size 24 hours) GROUP BY name HAVING COUNT(*) > 1;;
