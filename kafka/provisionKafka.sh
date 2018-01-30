#!/bin/sh -x
#
# 2018.01.23 kamaso: v.2
# Call this script to set up kafka node on a Centos7 box
#

# The three forst nodes are both zookeeper and Kafka broker nodes
zk1=st-linapp1029.st.statoil.no
zk2=st-linapp1030.st.statoil.no
zk3=st-linapp1031.st.statoil.no
kb1=$zk1
kb2=$zk2
kb3=$zk3
kafkaDir="/opt/kafka"
dataDirs="/data/disk01/kafka-logs" # These are the directly attached storage devices
zookeeperDataDir="$kafkaDir/zk-data"
keyStoreDir="/etc/Keystore"  # Remember to run ./cert.sh to populate the CA/keystore/truststore
scriptDir="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"

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
    service kafka stop
    service zookeeper stop
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

  if [ ! -f /etc/init.d/zookeeper ] ; then
    echo "Copy startup scripts from $scriptDir to /etc/init.d"
    cp $scriptDir/zookeeper /etc/init.d
    chkconfig --add zookeeper
  fi

  if [ ! -f /etc/init.d/kafka ] ; then
    cp $scriptDir/kafka /etc/init.d
    chkconfig --add kafka
  fi
}

firewall() {
  echo "Rough adding of firewall rules for zk and kafka"
  firewall-cmd --zone=public --add-port=2181/tcp --permanent   # Zookeeper public
  firewall-cmd --zone=public --add-port=2888/tcp --permanent   # Zookeeper internal
  firewall-cmd --zone=public --add-port=3888/tcp --permanent   # Zookeeper internal
  firewall-cmd --zone=public --add-port=9092/tcp --permanent   # Kafka plaintext
  firewall-cmd --zone=public --add-port=9093/tcp --permanent   # Kafka ssl
  firewall-cmd --zone=public --add-port=9999/tcp --permanent   # Kafka jmx
  firewall-cmd --zone=public --add-port=10000/tcp --permanent  # Kafka rmi
  firewall-cmd --reload
}

kbNode() {
  # Get broker id from hostname
  ID=$(hostname -s |  tr -dc '0-9' | tail -c 1)

  cat > $kafkaDir/current/config/server.properties <<EOF

broker.id=$ID

listeners=PLAINTEXT://$(hostname -f):9092;SSL://$(hostname -f):9093

log.dirs=$dataDirs

num.partitions=8
default.replication.factor=2
log.retention.bytes=100111000111
#offsets.topic.replication.factor=3
#transaction.state.log.replication.factor=3
transaction.state.log.min.isr=3
num.recovery.threads.per.data.dir=2
log.retention.hours=48
zookeeper.connect=$zk1:2181,$zk3:2181,$zk2:2181,
group.initial.rebalance.delay.ms=3

ssl.keystore.location=$keyStoreDir/$(hostname -f).keystore.jks
ssl.keystore.password=$(cat $keyStoreDir/$(hostname -f)_keystore_creds)
ssl.truststore.location=$keystoreDir/$(hostname -f).truststore.jks
ssl.truststore.password=$(cat $keyStoreDir/$(hostname -f)_truststore_creds)
ssl.key.password=$(cat $keyStoreDir/$(hostname -f)_sslkey_creds)
#ssl.client.auth=required
EOF
}

zkNode() {
  echo "Setting up for zookeeper"
  # Get zookeeper myid from last digit in hostname
  myId=$(hostname|  tr -dc '0-9' | tail -c 1)
  mkdir -p $zookeeperDataDir
  chown -R zookeeper:zookeeper $zookeeperDataDir
  echo $myId > $zookeeperDataDir/myid
  echo "zk myid: $myId"
  cat > $kafkaDir/current/config/zookeeper.properties <<EOF
dataDir=$zookeeperDataDir
clientPort=2181
tickTime=2000
initLimit=5
syncLimit=2
server.$(echo $zk1 | tr -dc '0-9' | tail -c 1)=$zk1:2888:3888
server.$(echo $zk2 | tr -dc '0-9' | tail -c 1)=$zk2:2888:3888
server.$(echo $zk3 | tr -dc '0-9' | tail -c 1)=$zk3:2888:3888
EOF
}

makeNodeSettings() {
  case $(hostname -f) in
   $zk1|$zk2|$zk3)  # Zookeeper and Kafka Brokers on these servers
            staging
            #firewall
            zkNode
            kbNode
            ;;
   *) # any additional servers are Kafka Brokers only
            staging
            #firewall
            kbNode
            ;;
  esac
}

#setJavaOptions
makeNodeSettings

echo "Done."
