#!/bin/bash -eu

set -o pipefail

# Build Fabric docker images

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric
make docker

# Listout all docker images
docker images | grep hyperledger*
