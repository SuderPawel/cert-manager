#!/bin/bash

##
# Based on https://jamielinux.com/docs/openssl-certificate-authority/create-the-root-pair.html
##

export __DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export __DIR="$( dirname ${__DIR} )"

if [ -d "${__DIR}/ca" ]; then
    echo "CA exists!"
    exit -1
fi

mkdir "${__DIR}/ca"

pushd "${__DIR}/ca"
  echo "Creating directories..."
  mkdir certs crl newcerts private
  echo "Setting permissions..."
  chmod 700 private
  echo "Creating index file..."
  touch index.txt
  echo "Creating serial file..."
  echo 1000 > serial
  echo "Copying OpenSSL configuration..."
  cp "${__DIR}/etc/openssl-ca.cnf" openssl.cnf
  echo "Modifying paths in configuration..."
  sed -i 's#/root/ca#'${__DIR}'/ca#g' openssl.cnf
  echo "Creating CA private key - you will be asked for password for new key"
  openssl genrsa -aes256 -out private/ca.key.pem 4096
  echo "Setting permissions..."
  chmod 400 private/ca.key.pem
  echo "Creating root CA certificate - you will be asked for few data related to CA"
  openssl req -config openssl.cnf \
        -key private/ca.key.pem \
        -new -x509 -days 7300 -sha256 -extensions v3_ca \
        -out certs/ca.cert.pem
  echo "Verifying certificate..."
  openssl x509 -noout -text -in certs/ca.cert.pem
popd
