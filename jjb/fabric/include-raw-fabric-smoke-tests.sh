#!/bin/bash

# Remove fabric-test repository
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test"
FABRIC_TEST_REPO_NAME=fabric-test
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$FABRIC_TEST_REPO_NAME $WD
cd $WD || exit

FABRIC_TEST_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC TEST COMMIT ========> $FABRIC_TEST_COMMIT"
echo
echo "FABRIC TEST COMMIT ========> $FABRIC_TEST_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log

# update submodules
git submodule update --init --recursive

# intialize govendor for chaincode tests
cd ../fabric/examples/chaincode/go/enccc_example || exit
go get -u github.com/kardianos/govendor && govendor init && govendor add +external

echo "========== Behave feature and system tests..."
echo
cd ../../../../../fabric-test/regression/smoke/ && ./runSmokeTestSuite.sh
