#!/bin/bash -eu
set -o pipefail

# Clone fabric git repository
#############################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
REPO_NAME=fabric
git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
cd $WD

set +e
BRANCH_NAME=$(echo $GERRIT_BRANCH | grep 'release-')
echo "-----> $BRANCH_NAME"
if [ ! -z "$BRANCH_NAME" ]; then
      echo "-----> Checkout to $GERRIT_BRANCH branch"
      git checkout $GERRIT_BRANCH
fi
echo "-----> $GERRIT_BRANCH"
set -e

FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "-----> FABRIC_COMMIT : $FABRIC_COMMIT"
echo "FABRIC_COMMIT ========> $FABRIC_COMMIT" >> commit_history.log
mv commit_history.log ${WORKSPACE}/gopath/src/github.com/hyperledger/

# export go version

GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
OS_VER=$(dpkg --print-architecture)
export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
export PATH=$GOROOT/bin:$PATH
echo "----> GO_VER" $GO_VER

set +e
BRANCH_NAME=$(echo $GERRIT_BRANCH | grep 'release-1.0')
echo "-----> $BRANCH_NAME"
if [ ! -z "$BRANCH_NAME" ]; then

     for IMAGES in docker release-clean release; do
        make $IMAGES
        if [ $? != 0 ]; then
           echo "-------> make $IMAGES failed"
           exit 1
        fi
     done

else

     for IMAGES in docker release-clean release docker-thirdparty; do
         make $IMAGES
         if [ $? != 0 ]; then
            echo "-------> make $IMAGES failed"
            exit 1
         fi
     done
fi
docker images | grep hyperledger
set -e

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone git://cloud.hyperledger.org/mirror/$CA_REPO_NAME $WD
cd $WD
set +e
BRANCH_NAME=$(echo $GERRIT_BRANCH | grep 'release-')
echo "------> $BRANCH_NAME"
if [ ! -z "$BRANCH_NAME" ]; then
      echo "-----> Checkout to $GERRIT_BRANCH branch"
      git checkout $GERRIT_BRANCH
fi
set -e
echo "-----> $GERRIT_BRANCH"
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "------> FABRIC_CA_COMMIT : $CA_COMMIT"
echo "CA COMMIT ========> $CA_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit_history.log

# export fabric-ca go version

GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
OS_VER=$(dpkg --print-architecture)
export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
export PATH=$GOROOT/bin:$PATH
echo "----> GO_VER" $GO_VER

make docker
if [ $? != 0 ]; then
   echo "--------> make docker failed"
   exit 1
fi
docker images | grep hyperledger
