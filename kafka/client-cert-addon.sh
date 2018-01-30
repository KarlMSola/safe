#!/bin/bash
# kamaso 2018
set -o errexit -e
umask 077
DIR="./Keystore"
cd $DIR

# Random password; will be stored in *_creds for use later
CAPASS=$(cat myca_creds) || (echo "You probably need to run ./cert.sh first...." && exit 1)

for i in client
do
  # Generate passwords
  KEYPASS=$(openssl rand -base64 24) && echo $KEYPASS > ${i}_creds
  KEYSTOREPASS=$KEYPASS
  TRUSTSTOREPASS=$KEYPASS

  # Step 1 - Create keystore
  keytool -genkey -noprompt -alias localhost \
          -dname "CN=$i.statoil.no, OU=security, O=Statoil, L=Stavanger, S=Rogaland, C=NO" \
          -keystore $i.keystore.jks -keyalg RSA -storepass $KEYSTOREPASS -keypass $KEYPASS 

  # Step 2 - Create truststore and import the CA cert from above.
  echo "yes" | keytool -keystore $i.truststore.jks -alias CARoot -import -file myca.crt -storepass $TRUSTSTOREPASS -keypass $KEYPASS

  # Step 3 - Create CSR, sign the key and import back into keystore
  keytool -keystore $i.keystore.jks -alias localhost -certreq -file $i.csr -storepass $KEYSTOREPASS -keypass $KEYPASS
  openssl x509 -req -CA myca.crt -CAkey myca.key -in $i.csr -out $i-signed.crt -days 3650 -CAcreateserial -passin pass:$CAPASS
  echo "yes" | keytool -keystore $i.keystore.jks -alias CARoot -import -file myca.crt -storepass $KEYSTOREPASS -keypass $KEYPASS
  echo "yes" | keytool -keystore $i.keystore.jks -alias localhost -import -file $i-signed.crt -storepass $KEYSTOREPASS -keypass $KEYPASS
done

