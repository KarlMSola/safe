#!/bin/sh
#
# 2017.11.01 kamaso: v.1
# Call this script to set up kafka node
#

# The three forst nodes are both zookeeper and Kafka broker nodes
zk1=st-lcsi01
zk2=st-lcsi02
zk3=st-lcsi03
kb1=$zk1
kb2=$zk2
kb3=$zk3
kb4=st-lcsi04
dataDir="/export/kafka"

#if ! [ $(rpm -q elasticsearch) ]; then
#  echo "Elasticsearch rpm not found"
#  exit
#fi

staging() {
  dlDir="/private/kamaso/dl/kafka"
  #mkdir -p  $dlDir 
  #cd $dlDir && wget http://apache.uib.no/kafka/0.11.0.2/kafka_2.11-0.11.0.2.tgz
  # http://apache.uib.no/kafka/0.10.2.1/kafka_2.11-0.10.2.1.tgz

  # Just drop everything while testing
  rm -rf /export/kafka

  mkdir -p $dataDir/kafka-logs
  
  cd $dataDir
  tar zxf $dlDir/kafka_2.11-0.11.0.2.tgz
  ln -s kafka_2.11-0.11.0.2 current
  chown -R kafka:hadoop $dataDir
}



kbNode() {
  # Get broker id from hostname
  ID=$(hostname -s |  tr -dc '0-9' | tail -c 1)

  cat > $dataDir/current/config/server.properties <<EOF

broker.id=$ID

listeners=PLAINTEXT://$HOSTNAME:9092

log.dirs=$dataDir/kafka-logs

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
  zookeeperDataDir=$dataDir/zookeeper
  mkdir -p $zookeeperDataDir
  chown -R zookeeper:hadoop $zookeeperDataDir
  echo $myId > $zookeeperDataDir/myid
  cat > $dataDir/current/config/zookeeper.properties <<EOF
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
            zkNode
            kbNode
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
