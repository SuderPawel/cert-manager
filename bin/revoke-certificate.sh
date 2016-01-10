#!/bin/bash

##
# Based on https://jamielinux.com/docs/openssl-certificate-authority/certificate-revocation-lists.html
##

export __DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export __DIR="$( dirname ${__DIR} )"

CN=${1}

if [ -z "${CN}" ]; then
    echo "Usage: ${0} <commonName>"
    exit -1
fi

if [ ! -d "${__DIR}/ca/intermediate" ]; then
    echo "Intermediate CA does not exist!"
    exit -1
fi

if ! grep -q crlDistributionPoints "${__DIR}/ca/intermediate/openssl.cnf"; then
    echo "CRL is not set!"
    exit -1
fi

pushd "${__DIR}/ca/intermediate"
  if [ -f "certs/${CN}.cert.pem" ]; then
    echo "Revoking certificate ${CN}"
    openssl ca -config openssl.cnf -revoke "certs/${CN}.cert.pem"
    echo "Recreating CRL..."
    openssl ca -config openssl.cnf -gencrl -out crl/intermediate.crl.pem
    echo "Checking CRL..."
    openssl crl -in crl/intermediate.crl.pem -noout -text
  else
    echo "${CN} does not exists!"
  fi
popd
