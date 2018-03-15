#!/usr/bin/env bash

CONFLUENT_HOME=../../confluent-4.0.0
## use a topic-producer to load the suspicious-names.json file onto a topic suspicious-names-json
$CONFLUENT_HOME/bin/kafka-console-producer --broker-list localhost:9092 --topic suspicious-names-json --property "parse.key=true" --property "key.separator=:" < resources/suspicious-names.json