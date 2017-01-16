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

# Clone fabric-cop git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-cop

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-cop"
COP_REPO_NAME=fabric-cop
git clone --depth=1 https://github.com/hyperledger/$COP_REPO_NAME.git $WD
cd $WD
COP_COMMIT=$(git log -1 --pretty=format:"%h")
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
cd test/fixtures
docker-compose up >> dockerlogfile.log 2>&1 &
docker ps
cd ../.. && npm install
npm config set prefix ~/npm && npm install -g gulp && npm install -g istanbul
gulp && gulp cop
rm -rf node_modules/hfc-cop && npm install
istanbul cover --report cobertura test/unit/end-to-end.js

echo "=======>" "FABRIC COMMIT NUMBER" "-" $FABRIC_COMMIT "=======>" "FABRIC COP COMMIT NUMBER" "-" $COP_COMMIT "=======>" "FABRIC SDK NODE COMMIT NUMBER" "-" $SDK_COMMIT >> commit_history.log
