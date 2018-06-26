#!/bin/bash -e
set -o pipefail

if [ "$GERRIT_BRANCH" != "release-1.0" ] || [ "$ARCH" != "s390x" ] || [ "$ARCH" != "ppc64le" ]; then
      echo "----> $GERRIT_BRANCH"
      # Move to fabric-sdk-java repository and execute end-to-end tests
      rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-java

      WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-java"
      SDK_REPO_NAME=fabric-sdk-java
      git clone git://cloud.hyperledger.org/mirror/$SDK_REPO_NAME $WD
      cd $WD
      if [[ "$GERRIT_BRANCH" = "release-1.2" ]]; then
          git checkout master
      elif [[ "$GERRIT_BRANCH" = *"release-"* ]]; then
          echo "-----> Checkout to $GERRIT_BRANCH branch"
          git checkout $GERRIT_BRANCH
      fi
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
