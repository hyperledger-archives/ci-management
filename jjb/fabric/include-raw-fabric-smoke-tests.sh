#!/bin/bash

# Remove fabric-test repository
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test"
FABRIC_TEST_REPO_NAME=fabric-test
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$FABRIC_TEST_REPO_NAME $WD

echo "=========> Install govendor"
go get -u github.com/kardianos/govendor

cd $WD || exit

FABRIC_TEST_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC TEST COMMIT ========> $FABRIC_TEST_COMMIT"
echo
echo "FABRIC TEST COMMIT ========> $FABRIC_TEST_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log

# update submodules
git submodule update --init --recursive

echo "========== Behave feature and system tests..."
echo
cd regression/smoke && ./runSmokeTestSuite.sh
