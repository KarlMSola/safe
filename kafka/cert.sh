#!/bin/bash
# kamaso 2018

#set -o nounset -o errexit -o verbose -o xtrace
set -o errexit
umask 077

DIR="./Keystore" # Destination directory for certs. You probably want to move this to /etc/Keytore or similar
mkdir -p $DIR && cd $DIR
# Delete previous rubbish attempts
#rm  *.key *.jks *.srl *.crt *_creds *.pem 

# Random password; will be stored in *_creds for use later
CAPASS=$(openssl rand -base64 24) && echo $CAPASS > myca_creds

# Generate key for new CA, myca, 10 year
openssl req -new -x509 -keyout myca.key -out myca.crt -days 3650 -subj '/CN=ca.pki.statoil.no/OU=pki/O=Statoil/L=Stavanger/S=Rogaland/C=NO' -passin pass:$CAPASS -passout pass:$CAPASS

# Kafkacat
KEYPASS=$(openssl rand -base64 24) && echo $KEYPASS > kafkacat-key_creds
openssl genrsa -des3 -passout "pass:$KEYPASS" -out kafkacat.client.key 1024
openssl req -passin "pass:$KEYPASS" -passout "pass:$KEYPASS" -key kafkacat.client.key -new -out kafkacat.client.req -subj '/CN=kafkacat.statoil.no/OU=pki/O=Statoil/L=Stavanger/S=Rogaland/C=NO'
openssl x509 -req -CA myca.crt -CAkey myca.key -in kafkacat.client.req -out kafkacat-signed.pem -days 3650 -CAcreateserial -passin "pass:$CAPASS"

BROKERS="ai-linapp1093.statoil.no ai-linapp1094.statoil.no ai-linapp1095.statoil.no" # Edit this list to match your servers
for i in $BROKERS
do
  # Generate passwords
  KEYPASS=$(openssl rand -base64 24) && echo $KEYPASS > ${i}_sslkey_creds
  KEYSTOREPASS=$(openssl rand -base64 24) && echo $KEYSTOREPASS > ${i}_keystore_creds
  TRUSTSTOREPASS=$(openssl rand -base64 24) && echo $TRUSTSTOREPASS > ${i}_truststore_creds

  # Step 1 - Create kafka server keystore
  keytool -genkey -noprompt -alias localhost \
          -dname "CN=$i.test.statoil.no, OU=security, O=Statoil, L=Stavanger, S=Rogaland, C=NO" \
          -keystore $i.keystore.jks -keyalg RSA -storepass $KEYSTOREPASS -keypass $KEYPASS -ext SAN=DNS:$i

  # Step 2 - Create truststore and import the CA cert from above.
  echo "yes" | keytool -keystore $i.truststore.jks -alias CARoot -import -file myca.crt -storepass $TRUSTSTOREPASS -keypass $KEYPASS

  # Step 3 - Create CSR, sign the key and import back into keystore
  keytool -keystore $i.keystore.jks -alias localhost -certreq -file $i.csr -storepass $KEYSTOREPASS -keypass $KEYPASS
  openssl x509 -req -CA myca.crt -CAkey myca.key -in $i.csr -out $i-signed.crt -days 3650 -CAcreateserial -passin pass:$CAPASS
  echo "yes" | keytool -keystore $i.keystore.jks -alias CARoot -import -file myca.crt -storepass $KEYSTOREPASS -keypass $KEYPASS
  echo "yes" | keytool -keystore $i.keystore.jks -alias localhost -import -file $i-signed.crt -storepass $KEYSTOREPASS -keypass $KEYPASS
done

# Delete signing request files and certs already imported into the keystore
rm *.csr kafkacat.client.req  *signed.crt

for i in $BROKERS
do
  echo "* For inclusion in $i server.properties:"
  echo "ssl.keystore.location=/etc/Keystore/$i.keystore.jks"
  echo "ssl.keystore.password=$(cat ${i}_keystore_creds)"
  echo "ssl.truststore.location=/etc/Keystore/$i.truststore.jks"
  echo "ssl.truststore.password=$(cat ${i}_truststore_creds)"
  echo "ssl.key.password=$(cat ${i}_sslkey_creds)"
  echo 
done

echo "use: kafkacat -C -b :9093 -t testtopic -X security.protocol=SSL -X ssl.ca.location=myca.crt"
echo
echo "tip: run client-cert-addon.sh to generate the extra certs for generic Kafka clients"
