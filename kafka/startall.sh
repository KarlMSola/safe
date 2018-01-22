#!/bin/sh
echo "Start zookeeper. Wait 5 seconds. Then start Kafka."
pdsh -w st-lcsi[01-03] sh /private/kamaso/dl/kafka/zookeeper.sh start
sleep 5
pdsh -w st-lcsi[01-04] sh /private/kamaso/dl/kafka/kafka.sh start
