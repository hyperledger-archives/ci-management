#!/bin/bash -eu
set -o pipefail

set +e
BRANCH_NAME=$(echo $GERRIT_BRANCH | grep 'release-')
echo "---> BRANCH_NAME"
if [ "$BRANCH_NAME" != "release-1.0" ] | [ "$ARCH" != "s390x" ] | [ "$ARCH" != "ppc64le" ]; then
       echo "----> $GERRIT_BRANCH"
set -e
       # Move to fabric-sdk-java repository and execute end-to-end tests
       rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-java

       WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-java"
       SDK_REPO_NAME=fabric-sdk-java
       git clone git://cloud.hyperledger.org/mirror/$SDK_REPO_NAME $WD
       cd $WD
set +e
      BRANCH_NAME=$(echo $GERRIT_BRANCH | grep 'release*')
      echo "-----> $BRANCH_NAME"
if [ ! -z "$BRANCH_NAME" ]; then
       echo "-----> Checkout to $GERRIT_BRANCH branch"
       git checkout $GERRIT_BRANCH
fi
       set -e
       echo "-----> $GERRIT_BRANCH"
       SDK_JAVA_COMMIT=$(git log -1 --pretty=format:"%h")
       echo "-----> SDK_JAVA_COMMIT : $SDK_JAVA_COMMIT"
       echo "-----> SDK_JAVA_COMMIT=======> $SDK_JAVA_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
       export GOPATH=$WD/src/test/fixture

       cd $WD/src/test
       chmod +x cirun.sh
       source cirun.sh
else
       echo "-----> TEMPORARILY SDK JAVA TESTS ARE DISABLED IN $GERRIT_BRANCH BRANCH"
fi
