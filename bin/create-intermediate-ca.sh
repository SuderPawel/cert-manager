#!/bin/bash

##
# Based on https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html
##

export __DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export __DIR="$( dirname ${__DIR} )"

if [ ! -d "${__DIR}/ca" ]; then
    echo "CA does not exist!"
    exit -1
fi

if [ -d "${__DIR}/ca/intermediate" ]; then
    echo "Intermediate CA exists!"
    exit -1
fi

mkdir "${__DIR}/ca/intermediate"

pushd "${__DIR}/ca/intermediate"
  echo "Creating directories..."
  mkdir certs crl csr newcerts private
  echo "Setting permissions..."
  chmod 700 private
  echo "Creating index file..."
  touch index.txt
  echo "Creating serial file..."
  echo 1000 > serial
  echo "Creating certificate revocation number file..."
  echo 1000 > crlnumber
  echo "Copying OpenSSL configuration..."
  cp "${__DIR}/etc/openssl-intermediate-ca.cnf" openssl.cnf
  echo "Modifying paths in configuration..."
  sed -i 's#/root/ca/intermediate#'${__DIR}'/ca/intermediate#g' openssl.cnf
  echo "Creating Intermediate CA private key - you will be asked for password for new key"
  openssl genrsa -aes256 \
      -out private/intermediate.key.pem 4096
  echo "Setting permissions..."
  chmod 400 private/intermediate.key.pem
  echo "Creating intermediate CA certificate - you will be asked for few data related to CA"
  openssl req -config openssl.cnf -new -sha256 \
        -key private/intermediate.key.pem \
        -out csr/intermediate.csr.pem
  echo "Singing intermediate CA certificate by root CA - you will be asked for password for root CA private key"
  openssl ca -config ../openssl.cnf -extensions v3_intermediate_ca \
      -days 3650 -notext -md sha256 \
      -in csr/intermediate.csr.pem \
      -out certs/intermediate.cert.pem
  echo "Setting permissions..."
  chmod 444 certs/intermediate.cert.pem
  echo "Verifying certificate..."
  openssl x509 -noout -text \
      -in certs/intermediate.cert.pem
  openssl verify -CAfile ../certs/ca.cert.pem \
      certs/intermediate.cert.pem
  echo "Creating CA chain..."
  cat certs/intermediate.cert.pem \
      ../certs/ca.cert.pem > certs/ca-chain.cert.pem
  echo "Setting permissions..."
  chmod 444 certs/ca-chain.cert.pem
popd
