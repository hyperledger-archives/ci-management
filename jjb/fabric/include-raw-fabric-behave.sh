#!/bin/bash -eu
set -o pipefail

make behave-deps -C ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric
cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/bddtests && docker images | grep "hyperledger"
behave -k -D logs=force -D cache-deployment-spec
#behave -k -D cache-deployment-spec features/bootstrap.feature
