#!/usr/bin/env bash

CONFLUENT_HOME=../../confluent-4.0.0

COUNTER=0
TXN_ID=10

declare -a RECIPIENTS=('joe blogs' 'larry ellison' 'randy white' 'alan sugar' 'arnold jerold');

declare -a NAMES=('alan jones' 'keith richards' 'bruce atkins' 'mary simpson' 'arnold jerold');


while [  $COUNTER -lt 10 ]; do
    for RECIPIENT in "${RECIPIENTS[@]}"
    do
        for NAME in "${NAMES[@]}"
        do
            # Set the key to ensure the detault partition assigner sends the records to the same partition
            MSG="$TXN_ID:{\"txn_id\":$TXN_ID,\"username\":\"$NAME\",\"recipient\":\"$RECIPIENT\", \"amount\":$((RANDOM % 100))}"
            $CONFLUENT_HOME/bin/kafka-console-producer --broker-list localhost:9092 --topic txns-1 --property "parse.key=true" --property "key.separator=:" <<< $MSG
            echo $MSG
            let TXN_ID=TXN_ID+1
        done
    done
    sleep 1
 let COUNTER=COUNTER+1
done
