#!/bin/bash -eu
set -o pipefail

cd gopath/src/github.com/hyperledger/fabric
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "-----> FABRIC_COMMIT : $FABRIC_COMMIT"
echo "FABRIC_COMMIT ===========> $FABRIC_COMMIT" >> commit.log
mv commit.log ${WORKSPACE}/gopath/src/github.com/hyperledger/

for IMAGES in docker release-clean release docker-thirdparty; do
   make $IMAGES
   if [ $? != 0 ]; then
       echo "-------> make $IMAGES failed"
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
set +e
BRANCH_NAME=$(echo $GERRIT_BRANCH | grep 'release-')
echo "-----> $BRANCH_NAME"
if [ ! -z "$BRANCH_NAME" ]; then
      echo "-----> Checkout to $GERRIT_BRANCH branch"
      git checkout $GERRIT_BRANCH
fi
set -e
echo "-----> $GERRIT_BRANCH"
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "-----> FABRIC_CA_COMMIT : $CA_COMMIT"

make docker
if [ $? != 0 ]; then
   echo "-------> make docker failed"
   exit 1
fi

docker images | grep hyperledger

echo "CA COMMIT ========> $CA_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
