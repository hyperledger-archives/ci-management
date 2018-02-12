#!/bin/bash -exu
set -o pipefail

echo "=========>Build FABRIC_CA Images<=========="
cd $GOPATH/src/github.com/hyperledger/fabric-ca
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "CA_COMMIT ===========> $CA_COMMIT" >> commit.log
mv commit.log ${WORKSPACE}/gopath/src/github.com/hyperledger/
make docker && docker images | grep hyperledger

# Clone fabric repository
echo "========>Cloning Fabric<=========="
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
REPO_NAME=fabric
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$REPO_NAME $WD
cd $WD || exit
git checkout $GERRIT_BRANCH
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC_COMMIT ===========> $FABRIC_COMMIT" >> commit.log
make docker && docker images | grep hyperledger
