#!/bin/bash -exu
set -o pipefail

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric
make docker && docker images | grep hyperledger

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone git://cloud.hyperledger.org/mirror/$CA_REPO_NAME $WD
cd $WD
make docker-fabric-ca && docker images | grep hyperledger
