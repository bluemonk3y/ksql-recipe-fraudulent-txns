#!/usr/bin/env bash

CONFLUENT_HOME=../../confluent-4.0.0

COUNTER=0
TXN_ID=9900
# the set of suspicious accounts
declare -a RECIPIENTS=('verizon' 'alcatel' 'best buy');

# default scenario only makes 1 bad account ;) -
declare -a NAMES=('alan jones');

while [  $COUNTER -lt 2 ]; do
    for RECIPIENT in "${RECIPIENTS[@]}"
    do
        for NAME in "${NAMES[@]}"
        do
            MSG="{\"txn_id\":$TXN_ID,\"username\":\"$NAME\",\"recipient\":\"$RECIPIENT\", \"amount\":$((RANDOM % 100))}"
            $CONFLUENT_HOME/bin/kafka-console-producer --broker-list localhost:9092 --topic txns-1 <<< $MSG
            echo $MSG
            let TXN_ID=TXN_ID+1
            sleep 1
        done
    done
 let COUNTER=COUNTER+1
done