#!/bin/bash -eu

set -o pipefail

# Build Fabric docker images

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

make docker

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/fabric-ca $WD
cd $WD
CA_COMMIT=$(git log -1 --pretty=format:"%h")
make docker

# Listout all docker images
docker images | grep hyperledger*
