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
    EXTENSIONS=server_cert
fi

pushd "${__DIR}/ca/intermediate"
  if [ ! -f "private/${CN}.key.pem" ]; then
    echo "Creating private key - you will be asked to provide password for new key"
    openssl genrsa -aes256 \
          -out "private/${CN}.key.pem" 2048
    echo "Setting permissions..."
    chmod 400 "private/${CN}.key.pem"
  fi
  if [ ! -f "csr/${CN}.csr.pem" ]; then
    echo "Generating certificate signing request - you will be asked for few data related to certificate"
    openssl req -config "openssl.cnf" \
          -key "private/${CN}.key.pem" \
          -new -sha256 -out "csr/${CN}.csr.pem"
  fi
  if [ ! -f "certs/${CN}.cert.pem" ]; then
    echo "Singing CSR by intermediate CA - you will be asked for password to intermediate CA private key"
    openssl ca -config "openssl.cnf" \
          -extensions ${EXTENSIONS} -days 375 -notext -md sha256 \
          -in "csr/${CN}.csr.pem" \
          -out "certs/${CN}.cert.pem"
    echo "Setting permissions..."
    chmod 444 "certs/${CN}.cert.pem"
  fi
  echo "Verifying certificate..."
  openssl x509 -noout -text \
        -in "certs/${CN}.cert.pem"
  openssl verify -CAfile "certs/ca-chain.cert.pem" \
        "certs/${CN}.cert.pem"
  if [ ! -f "${CN}.tar" ]; then
    if [ -f "certs/${CN}.cert.pem" ] && [ -f "private/${CN}.key.pem" ]; then
      echo "Creating ${__DIR}/ca/intermediate/${CN}.tar with private key and certificates: ${CN} and CA chain..."
      tar cf "${CN}.tar" "certs/${CN}.cert.pem" "private/${CN}.key.pem" "certs/ca-chain.cert.pem"
    else
      echo "Not exported..."
    fi
  else
    echo "Exported to ${CN}.tar"
  fi
popd
