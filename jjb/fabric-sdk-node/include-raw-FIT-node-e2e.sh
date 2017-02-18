#!/bin/bash -exu
set -o pipefail

# Clone fabric git repository
#############################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
REPO_NAME=fabric
git clone --depth=1 https://github.com/hyperledger/$REPO_NAME.git $WD
cd $WD
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
make docker
docker images | grep hyperledger

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone --depth=1 https://github.com/hyperledger/$CA_REPO_NAME.git $WD
cd $WD
CA_COMMIT=$(git log -1 --pretty=format:"%h")
make docker
docker images | grep hyperledger

# RUN END-to-END Test
#####################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node"
SDK_REPO_NAME=fabric-sdk-node
git clone --depth=1 https://github.com/hyperledger/$SDK_REPO_NAME.git $WD
cd $WD
SDK_COMMIT=$(git log -1 --pretty=format:"%h")

echo "=======>" "FABRIC PEER COMMIT NUMBER" "-" $FABRIC_COMMIT "=======>" "FABRIC CA COMMIT NUMBER" "-" $CA_COMMIT "=======>" "FABRIC SDK NODE COMMIT NUMBER" "-" $SDK_COMMIT >> commit_history.log
cd test/fixtures
cat docker-compose.yml > docker-compose.log
docker-compose up >> dockerlogfile.log 2>&1 &
sleep 10
docker ps
cd ../.. && npm install
npm config set prefix ~/npm && npm install -g gulp && npm install -g istanbul
gulp && gulp ca
rm -rf node_modules/fabric-ca-client && npm install
istanbul cover --report cobertura test/integration/end-to-end.js

