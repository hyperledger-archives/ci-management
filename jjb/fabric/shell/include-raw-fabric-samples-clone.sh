#!/bin/bash

# Clone fabric-samples.
######################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples

echo "######## Cloning fabric-samples ########"
git --depth=1 clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
cd $WD || exit
git checkout $GERRIT_BRANCH
echo "-------> GERRIT_BRANCH: $GERRIT_BRANCH"
FABRIC_SAMPLES_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC_SAMPLES_COMMIT ========> $FABRIC_SAMPLES_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
