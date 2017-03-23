#!/bin/bash -exu
set -o pipefail

source ${WORKSPACE}/src/test/fabric_test_commitlevel.sh

# Clone fabric git repository
#############################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
REPO_NAME=fabric
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$REPO_NAME $WD
cd $WD
if [ "$FABRIC_COMMIT" == "latest" ]; then
echo "Fabric commit is $FABRIC_COMMIT so go with this"
else
git checkout $FABRIC_COMMIT
FABRIC_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
fi
FABRIC_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
# Build fabric Docker images
make docker
docker images | grep hyperledger

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$CA_REPO_NAME $WD
cd $WD
if [ "$FABRIC_CA_COMMIT" == "latest" ]; then
echo "Fabric_CA commit is $FABRIC_COMMIT so go with this"
else
git checkout $FABRIC_CA_COMMIT
CA_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
fi
CA_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
# Build CA Docker Images
make docker
docker images | grep hyperledger

# Move to fabric-sdk-java repository and execute SDK end-to-end tests

export WD=${WORKSPACE}
cd $WD
JAVA_SDK_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
echo "=======>" "FABRIC COMMIT NUMBER" "-" $FABRIC_COMMIT_LEVEL "=======>" "FABRIC CA COMMIT NUMBER" "-" $CA_COMMIT_LEVEL "=======>" "FABRIC SDK JAVA COMMIT NUMBER" "-" $JAVA_SDK_COMMIT_LEVEL >> commit_history.log
export GOPATH=$WD/src/test/fixture

cd $WD/src/test
chmod +x cirun.sh
source cirun.sh
