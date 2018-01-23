#!/bin/sh
echo "Stop zookeeper. Wait 5 seconds. Then stop Kafka."
pdsh -w ai-linapp[1093-1095] sh  /home/centos/safe/kafka/zookeeper.sh stop
sleep 2
pdsh -w ai-linapp[1093-1095] sh /home/centos/safe/kafka/kafka.sh stop
