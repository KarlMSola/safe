#!/bin/sh
echo "Stop zookeeper. Wait 5 seconds. Then stop Kafka."
pdsh -w st-lcsi[01-03] sh /private/kamaso/dl/kafka/zookeeper.sh stop
sleep 2
pdsh -w st-lcsi[01-04] sh /private/kamaso/dl/kafka/kafka.sh stop
