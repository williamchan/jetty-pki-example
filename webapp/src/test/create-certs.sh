#!/bin/bash
 
CA_PASSWORD=6pSC5p8vf0nDv%*j
SERVER_PASSWORD=g7^w@IzOgkPdBZjK
CLIENT_PASSWORD=4wBtxVCpDSL@4PR8

OUT_DIR=certs

# Subject items
C="US"
ST="CA"
L="Redwood City"
O="PaxataDev"

# Do not reuse this for multiple CA certs.
CN_CA="PaxataDev Root CA"
# This needs to be localhost if testing on https://localhost
CN_SERVER="localhost"
CN_CLIENT="Paxata User userA"
 
###############################
 
# Create output directory
mkdir -p ${OUT_DIR}
 
###############################
 
# create CA key
openssl genrsa -des3 -out ${OUT_DIR}/ca.key -passout pass:${CA_PASSWORD} 4096
 
# create CA cert
openssl req -new -x509 -days 1500 -key ${OUT_DIR}/ca.key -out ${OUT_DIR}/ca.crt \
 -passin pass:${CA_PASSWORD} -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/CN=${CN_CA}/"

# create truststore
keytool -import -trustcacerts -alias caroot -file ${OUT_DIR}/ca.crt \
 -keystore ${OUT_DIR}/truststore.jks -storepass ${CA_PASSWORD} -noprompt

###############################

# create server key
openssl genrsa -des3 -out ${OUT_DIR}/server.key -passout pass:${SERVER_PASSWORD} 4096

# create server cert request
openssl req -new -key ${OUT_DIR}/server.key -out ${OUT_DIR}/server.csr \
 -passin pass:${SERVER_PASSWORD} -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/CN=${CN_SERVER}/"

# create server cert
openssl x509 -req -days 1500 -in ${OUT_DIR}/server.csr -CA ${OUT_DIR}/ca.crt \
 -CAkey ${OUT_DIR}/ca.key -set_serial 01 -out ${OUT_DIR}/server.crt \
 -passin pass:${CA_PASSWORD}

# convert server cert to PKCS12 format, including key
openssl pkcs12 -export -out ${OUT_DIR}/server.p12 -inkey ${OUT_DIR}/server.key \
 -in ${OUT_DIR}/server.crt -passin pass:${SERVER_PASSWORD} -passout pass:${SERVER_PASSWORD}

keytool -v -importkeystore -srckeystore ${OUT_DIR}/server.p12 -srcstoretype PKCS12 \
 -destkeystore ${OUT_DIR}/keystore.jks -deststoretype JKS \
 -srcstorepass ${SERVER_PASSWORD} -deststorepass ${SERVER_PASSWORD}

###############################

# create client key
openssl genrsa -des3 -out ${OUT_DIR}/client.key -passout pass:${CLIENT_PASSWORD} 4096

# create client cert request
openssl req -new -key ${OUT_DIR}/client.key -out ${OUT_DIR}/client.csr \
 -passin pass:${CLIENT_PASSWORD} -subj "/C=${C}/ST=${ST}/L=${L}/O=${O}/CN=${CN_CLIENT}/"

# create client cert
openssl x509 -req -days 1500 -in ${OUT_DIR}/client.csr -CA ${OUT_DIR}/ca.crt \
 -CAkey ${OUT_DIR}/ca.key -set_serial 02 -out ${OUT_DIR}/client.crt \
 -passin pass:${CA_PASSWORD}

# convert client cert to PKCS12, including key
openssl pkcs12 -export -out ${OUT_DIR}/client.p12 -inkey ${OUT_DIR}/client.key \
 -in ${OUT_DIR}/client.crt -passin pass:${CLIENT_PASSWORD} -passout pass:${CLIENT_PASSWORD}

###############################

# create client cert, this one expires in one day
openssl x509 -req -days 1 -in ${OUT_DIR}/client.csr -CA ${OUT_DIR}/ca.crt \
 -CAkey ${OUT_DIR}/ca.key -set_serial 03 -out ${OUT_DIR}/expired-client.crt \
 -passin pass:${CA_PASSWORD}

# convert expiring client cert to PKCS12, including key
openssl pkcs12 -export -out ${OUT_DIR}/expired-client.p12 -inkey ${OUT_DIR}/client.key \
 -in ${OUT_DIR}/expired-client.crt -passin pass:${CLIENT_PASSWORD} -passout pass:${CLIENT_PASSWORD}
