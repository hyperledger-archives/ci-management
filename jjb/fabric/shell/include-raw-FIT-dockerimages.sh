#!/bin/bash -e
set -o pipefail

# Checkout to fabric repository
################################

cd gopath/src/github.com/hyperledger/fabric
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "------> FABRIC_COMMIT : $FABRIC_COMMIT"
echo "FABRIC_COMMIT ------> $FABRIC_COMMIT" >> commit.log
mv commit.log ${WORKSPACE}/gopath/src/github.com/hyperledger/
echo "-------> fabric GERRIT_BRANCH:" $GERRIT_BRANCH

# Gerrit Checkout to Branch
if [[ "$GERRIT_BRANCH" = "release-1.0" ]]; then

     for IMAGES in docker release-clean release; do
        make $IMAGES
        if [ $? != 0 ]; then
           echo "------> make $IMAGES failed"
           exit 1
        fi
     done
else
     for IMAGES in docker release-clean release docker-thirdparty; do
         make $IMAGES
         if [ $? != 0 ]; then
            echo "------> make $IMAGES failed"
            exit 1
         fi
     done
fi
docker images | grep hyperledger

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone git://cloud.hyperledger.org/mirror/$CA_REPO_NAME $WD
cd $WD

# Gerrit checkout to Branch
if [[ "$GERRIT_BRANCH" = *"release-"* ]]; then
     echo "-----> Checkout to $GERRIT_BRANCH branch"
     git checkout $GERRIT_BRANCH
fi

echo "-----> fabric-ca GERRIT_BRANCH:" $GERRIT_BRANCH
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "-----> FABRIC_CA_COMMIT : $CA_COMMIT"

if [[ "$GERRIT_BRANCH" = "release-1.0" ]]; then
     # Build only fabric-ca docker image
     make docker-fabric-ca
     if [ $? != 0 ]; then
         echo "------> make docker-fabric-ca failed"
         exit 1
     fi
else
         make docker
         if [ $? != 0 ]; then
            echo "------> make docker failed"
            exit 1
         fi
fi
docker images | grep hyperledger
echo "CA COMMIT ------> $CA_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
