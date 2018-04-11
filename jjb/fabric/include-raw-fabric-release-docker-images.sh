#!/bin/bash -eu
set -o pipefail

# Clone fabric git repository
#############################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
REPO_NAME=fabric
git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
cd $WD
git checkout tags/v1.1.0-alpha
curl -sSL https://goo.gl/6wtTN5 | bash -s 1.1.0-alpha
docker images | grep hyperledger
