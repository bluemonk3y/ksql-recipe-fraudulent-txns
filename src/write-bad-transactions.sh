#!/usr/bin/env bash

CONFLUENT_HOME=../../confluent-4.0.0


COUNTER=0
TXN_ID=9999
# the set of suspicious accounts
declare -a RECIPIENTS=('verizon' 'alcatel' 'best buy');

# default scenario only makes 1 bad account ;) -
declare -a NAMES=('alan jones');

while [  $COUNTER -lt 10 ]; do
    for RECIPIENT in "${RECIPIENTS[@]}"
    do
        for NAME in "${NAMES[@]}"
        do
            MSG="$TXN_ID:{\"txn\":$TXN_ID,\"name\":\"$NAME\",\"recipient\":\"$RECIPIENT\", \"amount\":$((RANDOM % 100))}"
            $CONFLUENT_HOME/bin/kafka-console-producer --broker-list localhost:9092 --topic txns-1 --property "parse.key=true" --property "key.separator=:" <<< $MSG
            echo $TXN_ID:{ \"txn\":$TXN_ID, \"name\":\"$NAME\", \"recipient\":\"$RECIPIENT\" }
            let TXN_ID=TXN_ID+1
            sleep 1
        done
    done
 let COUNTER=COUNTER+1
done