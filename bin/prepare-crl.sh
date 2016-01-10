#!/bin/bash

##
# Based on https://jamielinux.com/docs/openssl-certificate-authority/certificate-revocation-lists.html
##

export __DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export __DIR="$( dirname ${__DIR} )"

CRL_URL=${1}

if [ -z "${CRL_URL}" ]; then
    echo "Usage: ${0} <crlUrl>"
    exit -1
fi

if [ ! -d "${__DIR}/ca/intermediate" ]; then
    echo "Intermediate CA does not exist!"
    exit -1
fi

pushd "${__DIR}/ca/intermediate"
  if ! grep -q crlDistributionPoints openssl.cnf; then
    echo "Updating intermediate CA configuration..."
    sed -i 's#\[ server_cert \]#[ server_cert ]\ncrlDistributionPoints = URI:'${CRL_URL}'#g' openssl.cnf
    echo "Creating CRL..."
    openssl ca -config openssl.cnf -gencrl -out crl/intermediate.crl.pem
  fi
  echo "Checking CRL..."
  openssl crl -in crl/intermediate.crl.pem -noout -text
popd
