#!/bin/bash -eu
set -o pipefail

# Clone fabric git repository
#############################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
REPO_NAME=fabric
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$REPO_NAME $WD
cd $WD
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC_COMMIT ========> $FABRIC_COMMIT" >> commit_history.log
mv commit_history.log ${WORKSPACE}/gopath/src/github.com/hyperledger/

# export fabric go version

GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
OS_VER=$(dpkg --print-architecture)
echo "-----> ARCH: $OS_VER"
export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
export PATH=$GOROOT/bin:$PATH
echo "----> GO_VER" $GO_VER

for IMAGES in docker-thirdparty ccenv peer-docker orderer-docker tools-docker release-clean release; do
    make $IMAGES
    if [ $? != 0 ]; then
        echo "-----> make $IMAGES failed"
        exit 1
    fi
done

docker images | grep hyperledger

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$CA_REPO_NAME $WD
cd $WD
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "CA COMMIT ========> $CA_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit_history.log

# export fabric-ca go version

GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
OS_VER=$(dpkg --print-architecture)
echo "-----> ARCH: $OS_VER"
export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
export PATH=$GOROOT/bin:$PATH
echo "----> GO_VER" $GO_VER

make docker-fabric-ca

if [ $? != 0 ]; then
   echo "-----> make docker-fabric-ca failed"
   exit 1
fi

docker images | grep hyperledger
