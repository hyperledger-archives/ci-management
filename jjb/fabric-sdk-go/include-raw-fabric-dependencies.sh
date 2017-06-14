#!/bin/bash -exu
set -o pipefail

# Move to fabric-sdk-go repository and execute integration tests
export WD=${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-go
cd $WD
GO_SDK_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
echo "=======>" "FABRIC SDK GO COMMIT NUMBER" "-" $GO_SDK_COMMIT_LEVEL >> commit_history.log
export GOPATH=${WORKSPACE}/gopath
make integration-test
