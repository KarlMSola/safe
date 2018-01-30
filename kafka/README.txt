# 
# kamaso 2018
#
#
This set of scripts is inteded for setting up a self contained Zookeeper and Kafka cluster.
It has been tested with Centos6 and 7 only (or tested barely? - It works for me anyway...)

1. Start off by putting the names of your servers into the *.sh shell scripts and
   consider changing the directory names defined.

2. Generate certs by running the two cert.sh script.
   $ ./cert.sh
   Copy the resulting directory of key material into the preferred directory on each 
   server. I prefer /etc/Keystore/. 

3. Generate additional certs for use on Kafka or Logstash or whatever client you like. 
   Again, you need to edit the script to your need:
   $ ./client-cert-addon.sh


4. Provision the Zookeeper and Kafka software, firewall settings, etcetera:
   $ sudo ./provisionKafka.sh

5. If everything went fine, you should now have zookeeper and Kafka software installed 
    on the server. Repeat on all servers needed.

6. On each server, start zookeeper:
   $ sudo service zookeeper start

7. On each server, start kafka:
   $ sudo service kafka start

Other files to consider looking at:
 kafka        # Startup script for kafka. Note the SysV style. E.g.: service kafka start
 zookeeper    # Startup script for zookeeper. Note: SysV style.
