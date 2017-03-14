#!/bin/bash -exu
set -o pipefail

# Clone fabric git repository
#############################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
REPO_NAME=fabric
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$REPO_NAME $WD
cd $WD
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
make docker
docker images | grep hyperledger

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$CA_REPO_NAME $WD
cd $WD
CA_COMMIT=$(git log -1 --pretty=format:"%h")
make docker
docker images | grep hyperledger

# RUN END-to-END Test
#####################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node"
SDK_REPO_NAME=fabric-sdk-node
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$SDK_REPO_NAME $WD
cd $WD
SDK_COMMIT=$(git log -1 --pretty=format:"%h")

echo "=======>" "FABRIC PEER COMMIT NUMBER" "-" $FABRIC_COMMIT "=======>" "FABRIC CA COMMIT NUMBER" "-" $CA_COMMIT "=======>" "FABRIC SDK NODE COMMIT NUMBER" "-" $SDK_COMMIT >> commit_history.log
cd test/fixtures
cat docker-compose.yaml > docker-compose.log
docker-compose up >> dockerlogfile.log 2>&1 &
sleep 10
docker ps -a
cd ../../.. && npm install
npm config set prefix ~/npm && npm install -g gulp && npm install -g istanbul
gulp && gulp ca
rm -rf node_modules/fabric-ca-client && npm install
istanbul cover --report cobertura test/integration/e2e.js

