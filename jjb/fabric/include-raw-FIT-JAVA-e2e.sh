#!/bin/bash -exu
set -o pipefail

# Move to fabric-sdk-java repository and execute end-to-end tests
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-java

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-java"
SDK_REPO_NAME=fabric-sdk-java
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$SDK_REPO_NAME $WD
cd $WD
SDK_JAVA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "SDK_JAVA_COMMIT=======> $SDK_JAVA_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
export GOPATH=$WD/src/test/fixture

cd $WD/src/test
chmod +x cirun.sh
./cirun.sh
