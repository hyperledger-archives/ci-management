#!/bin/bash

set -o pipefail

# Clone fabric git repository
#############################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
FABRIC_REPO_NAME=fabric
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$FABRIC_REPO_NAME $WD
cd $WD || true
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC_COMMIT ===========> $FABRIC_COMMIT" >> commit.log
mv commit.log ${WORKSPACE}/gopath/src/github.com/hyperledger/

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$CA_REPO_NAME $WD
cd $WD || true
CA_COMMIT=$(git log -1 --pretty=format:"%h")

echo "CA COMMIT ========> $CA_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
