#!/bin/bash -exu
set -o pipefail

# RUN END-to-END Test
#####################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node"
SDK_REPO_NAME=fabric-sdk-node
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$SDK_REPO_NAME $WD
cd $WD
SDK_NODE_COMMIT=$(git log -1 --pretty=format:"%h")
echo "SDK_NODE_COMMIT=======> $SDK_NODE_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
cd test/fixtures
docker rm -f $(docker ps -aq) || true
docker-compose up >> node_dockerlogfile.log 2>&1 &
sleep 10
docker ps -a
cd ../../.. && npm install
npm config set prefix ~/npm && npm install -g gulp && npm install -g istanbul
gulp && gulp ca
rm -rf node_modules/fabric-ca-client && npm install
istanbul cover --report cobertura test/integration/e2e.js
docker rm -f $(docker ps -aq) || true
