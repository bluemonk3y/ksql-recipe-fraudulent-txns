
--1. run the load-suspicious_accounts.sh to populate the topic 'suspicious_accounts-json' topic
CREATE TABLE suspicious_accounts (company_name varchar, company_id int) with (key='company_name', kafka_topic = 'suspicious-accounts-json', value_format = 'json');
CREATE TABLE valid_accounts (key varchar, company_name varchar, company_id int) with (key='company_name', kafka_topic = 'valid-accounts-json', value_format = 'json');

-- 2. create a stream for user transactions
CREATE STREAM txns (txn_id long, username varchar, recipient varchar, amount double) with (kafka_topic = 'txns-1', value_format = 'json');



-- 3. join the stream with suspicious-names to identify potential threats
-- NOTE: the join will emit a 'null' event when it failed to join - to prevent the event we use an 'is not null filter'

CREATE STREAM suspicious_txns AS SELECT username + '-' + recipient as sus_key, txn_id, username, amount, recipient, company_name as sus_company_name FROM txns LEFT JOIN suspicious_accounts ON txns.recipient = suspicious_accounts.company_name WHERE company_name is not null;

-- 4. check if this user has seen these events in the last 30 days - if they have then we assume it is safe
-- to view the joined data
-- SELECT key, sus_key, sus_username, txn_id, sus_amount, sus_company_name, company_name FROM suspicious_txns LEFT JOIN valid_accounts ON suspicious_txns.sus_key = valid_accounts.key
-- still invalid txns will have a null join against key
-- SELECT key, sus_key, sus_username, txn_id, sus_amount, sus_company_name, company_name FROM suspicious_txns LEFT JOIN valid_accounts ON suspicious_txns.sus_key = valid_accounts.key where key is null;
CREATE STREAM still_invalid_txns AS SELECT key, sus_key, username, txn_id, amount, sus_company_name, company_name FROM suspicious_txns LEFT JOIN valid_accounts ON suspicious_txns.sus_key = valid_accounts.key where key is null;


-- 5. now use a window to determine that a breach occurs if we see *new* transactions against *suspicious counterparties* (i.e. > 1 events within the window)
CREATE TABLE fraud_event AS SELECT username, COUNT(*) AS txn_count FROM still_invalid_txns WINDOW TUMBLING (size 24 hours) GROUP BY username HAVING COUNT(*) > 1;

-- DIFFERENT USECASE - user level analysis
--
-- Count the number of unique users in the system

CREATE STREAM fixed_txns AS select 'fixed_key' as fixed_key, * from txns;

CREATE TABLE top_users AS SELECT fixed_key, topk(username, 10) from fixed_txns group by fixed_key;

CREATE TABLE top_users AS SELECT fixed_key, topk(username, 10) from fixed_txns group by fixed_key;

CREATE TABLE concurrent_users AS SELECT fixed_key, topkdistinct(username, 100) from fixed_txns group by fixed_key;

CREATE TABLE top_txns_per_user AS SELECT username, topkdistinct(recipient, 10) from txns group by username;