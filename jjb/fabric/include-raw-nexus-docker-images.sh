#!/bin/bash -exu
set -o pipefail

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric
make docker && docker images | grep hyperledger

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$CA_REPO_NAME $WD
cd $WD
make docker && docker images | grep hyperledger
