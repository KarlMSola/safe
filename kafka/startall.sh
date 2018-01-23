#!/bin/sh
echo "Start zookeeper. Wait 5 seconds. Then start Kafka."
pdsh -w ai-linapp[1093-1095] sh /home/centos/safe/kafka/zookeeper.sh start
sleep 5
pdsh -w ai-linapp[1093-1095] sh /home/centos/safe/kafka/kafka.sh start
