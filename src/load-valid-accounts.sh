#!/usr/bin/env bash

CONFLUENT_HOME=../../confluent-4.0.0
$CONFLUENT_HOME/bin/kafka-console-producer --broker-list localhost:9092 --topic valid-accounts-json --property "parse.key=true" --property "key.separator=:" < resources/valid-accounts.json