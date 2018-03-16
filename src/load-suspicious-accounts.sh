#!/usr/bin/env bash

CONFLUENT_HOME=../../confluent-4.0.0
$CONFLUENT_HOME/bin/kafka-console-producer --broker-list localhost:9092 --topic suspicious-accounts-json --property "parse.key=true" --property "key.separator=:" < resources/suspicious-accounts.json