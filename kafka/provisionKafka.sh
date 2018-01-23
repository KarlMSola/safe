#!/bin/sh
#
# 2018.01.23 kamaso: v.2
# Call this script to set up kafka node on a Centos7 box
#

# The three forst nodes are both zookeeper and Kafka broker nodes
zk1=ai-linapp1093.statoil.no
zk2=ai-linapp1094.statoil.no
zk3=ai-linapp1095.statoil.no
kb1=$zk1
kb2=$zk2
kb3=$zk3
kafkaDir="/opt/kafka"
dataDirs="/data01/kafka-logs,/data02/kafka-logs,/data03/kafka-logs"
zookeeperDataDir="$kafkaDir/zk-data"

staging() {
  dlDir="/tmp"

  echo "Downloading kafka"
  if [ -f "$dlDir/kafka_2.11-0.11.0.2.tgz" ] ; then
    echo "Kafka is downloaded already"
  else
    cd $dlDir && wget http://apache.uib.no/kafka/0.11.0.2/kafka_2.11-0.11.0.2.tgz 
    # http://apache.uib.no/kafka/0.10.2.1/kafka_2.11-0.10.2.1.tgz
  fi


  # Just drop everything in Kafka dir while testing
  if [ -d $kafkaDir ] ; then
    rm -rf $kafkaDir
  fi
  mkdir -p $kafkaDir

  # Just drop everything in data dirs while testing
  if [ -d $(echo $dataDirs | sed 's/,/ /g' | cut -d \  -f 1) ] ; then
    rm -rf  $(echo $dataDirs | sed 's/,/ /g')
  fi
  mkdir -p $(echo $dataDirs | sed 's/,/ /g')

  if [ -d $kafkaDir ] ; then
    echo "Unpack Kafka to $kafkaDir"
    cd $kafkaDir
    tar zxf $dlDir/kafka_2.11-0.11.0.2.tgz
    ln -s kafka_2.11-0.11.0.2 current
  fi

  echo "Add users kafka and zookeeper"
  sudo adduser --system --user-group --no-create-home kafka
  sudo adduser --system --user-group --no-create-home zookeeper
  chown -R kafka:kafka $kafkaDir $(echo $dataDirs | sed 's/,/ /g')
}



kbNode() {
  # Get broker id from hostname
  ID=$(hostname -s |  tr -dc '0-9' | tail -c 1)

  cat > $kafkaDir/current/config/server.properties <<EOF

broker.id=$ID

listeners=PLAINTEXT://$HOSTNAME:9092

log.dirs=$dataDirs

num.partitions=8
log.retention.bytes=100111000111
offsets.topic.replication.factor=3
transaction.state.log.replication.factor=3
transaction.state.log.min.isr=3
num.recovery.threads.per.data.dir=2
log.retention.hours=72
zookeeper.connect=$zk1:2181,$zk3:2181,$zk2:2181,
group.initial.rebalance.delay.ms=3
EOF
}

zkNode() {
  # Get zookeeper myid from last digit in hostname
  myId=$(hostname|  tr -dc '0-9' | tail -c 1)
  mkdir -p $zookeeperDataDir
  chown -R zookeeper:zookeeper $zookeeperDataDir
  echo $myId > $zookeeperDataDir/myid
  cat > $kafkaDir/current/config/zookeeper.properties <<EOF
dataDir=$zookeeperDataDir
clientPort=2181
tickTime=2000
initLimit=5
syncLimit=2
server.1=$zk1:2888:3888
server.2=$zk2:2888:3888
server.3=$zk3:2888:3888
EOF
}

makeNodeSettings() {
  case $(hostname) in
   $zk1|$zk2|$zk3) 
            staging
            #zkNode
            #kbNode
            ;;
   *) 
            staging
            kbNode
            ;;
  esac
}

#setJavaOptions
makeNodeSettings

echo "Done."
