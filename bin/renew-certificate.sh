#!/bin/bash

##
# Based on https://jamielinux.com/docs/openssl-certificate-authority/sign-server-and-client-certificates.html
##

export __DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export __DIR="$( dirname ${__DIR} )"

CN=${1}
EXTENSIONS=${2}

if [ -z "${CN}" ]; then
    echo "Usage: ${0} <commonName> (<extensions>)"
    exit -1
fi

if [ ! -d "${__DIR}/ca/intermediate" ]; then
    echo "Intermediate CA does not exist!"
    exit -1
fi

if [ -z "${EXTENSIONS}" ]; then
    EXTENSIONS=usr_cert
fi

pushd "${__DIR}/ca/intermediate"
  if [ ! -f "private/${CN}.key.pem" ]; then
    echo "Private key does not exist!"
    exit -1
  fi
  if [ ! -f "csr/${CN}.csr.pem" ]; then
    echo "Certificate signing request does not exist!"
    exit -1
  fi

  echo "Setting permissions..."
  chmod 644 "certs/${CN}.cert.pem"

  echo "Singing CSR by intermediate CA - you will be asked for password to intermediate CA private key"
  openssl ca -config "openssl.cnf" \
        -extensions ${EXTENSIONS} -days 375 -notext -md sha256 \
        -in "csr/${CN}.csr.pem" \
        -out "certs/${CN}.cert.pem"

  echo "Setting permissions..."
  chmod 444 "certs/${CN}.cert.pem"

  echo "Verifying certificate..."
  openssl x509 -noout -text \
        -in "certs/${CN}.cert.pem"
  openssl verify -CAfile "certs/ca-chain.cert.pem" \
        "certs/${CN}.cert.pem"

  if [ -f "certs/${CN}.cert.pem" ] && [ -f "private/${CN}.key.pem" ]; then
    echo "Creating ${__DIR}/ca/intermediate/${CN}.tar with private key and certificates: ${CN} and CA chain..."
    tar cf "${CN}.tar" "certs/${CN}.cert.pem" "private/${CN}.key.pem" "certs/ca-chain.cert.pem"
  else
    echo "Not exported..."
  fi
popd
