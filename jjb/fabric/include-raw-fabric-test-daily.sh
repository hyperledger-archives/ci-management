#!/bin/bash -eu
set -o pipefail

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test

# update submodules
git submodule update --init --recursive

# intialize govendor for chaincode tests
cd ../fabric/examples/chaincode/go/enccc_example
go get -u github.com/kardianos/govendor && govendor init && govendor add +external

# Run Dailytestsuite
cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test/regression/daily
./runDailyTestSuite.sh

# Copy .csv files to $WORKSPACE directory
cp -r /tmp/experiments .
