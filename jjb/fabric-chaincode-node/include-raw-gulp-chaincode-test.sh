#!/bin/bash -eu
set -o pipefail

# Test fabric-chaincode-node tests
##################################

REPO_PATH="${WORKSPACE}/gopath/src/github.com/hyperledger"
cd $REPO_PATH
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/fabric-samples
cd $REPO_PATH/fabric-chaincode-node
npm install
npm config set prefix ~/npm && npm install -g gulp

# Execute Integration test
npm test

# copy debug log file to $WORKSPACE directory

if [ $? == 0 ]; then
   # Copy Debug log to $WORKSPACE
   cp /tmp/fabric-shim/logs/*.log $WORKSPACE
else
   # Copy Debug log to $WORKSPACE
   cp /tmp/fabric-shim/logs/*.log $WORKSPACE
exit 1

fi
