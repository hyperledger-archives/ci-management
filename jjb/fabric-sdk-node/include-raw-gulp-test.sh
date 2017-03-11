#!/bin/bash -exu
set -o pipefail

# Clone fabric git repository
#############################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
REPO_NAME=fabric
git clone https://github.com/hyperledger/$REPO_NAME.git $WD
cd $WD
#sed -i -e 's/127.0.0.1:7050\b/'"orderer:7050"'/g' $WD/common/configtx/tool/configtx.yaml
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "=======> FABRIC_COMMIT <======= $FABRIC_COMMIT"
make peer-docker && make orderer-docker
docker images | grep hyperledger

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone https://github.com/hyperledger/$CA_REPO_NAME.git $WD
cd $WD
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "======> CA_COMMIT <======= $CA_COMMIT"
make docker
docker images | grep hyperledger

## Test gulp test
cd ${WORKSPACE}/gopath/src/github.com/fabric-sdk-node/test/fixtures/channel
docker-compose up >> dockerlogfile.log 2>&1 &
sleep 15
docker ps -a

cd ${WORKSPACE}/gopath/src/github.com/fabric-sdk-node && npm install
npm config set prefix ~/npm && npm install -g gulp && npm install -g istanbul
gulp || exit 1
gulp ca || exit 1
rm -rf node_modules/fabric-ca-client && npm install
gulp test


