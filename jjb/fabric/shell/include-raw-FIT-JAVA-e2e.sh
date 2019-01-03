#!/bin/bash -e
#
# SPDX-License-Identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 IBM Corporation, The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License 2.0
# which accompanies this distribution, and is available at
# https://www.apache.org/licenses/LICENSE-2.0
##############################################################################
set -o pipefail

echo "---------> GERRIT_BRANCH" $GERRIT_BRANCH
echo "---------> ARCH" $ARCH
if [ "$GERRIT_BRANCH" != "release-1.0" ] && [ "$GERRIT_BRANCH" != "master" ] && [ "$ARCH" != "s390x" ] && [ "$ARCH" != "ppc64le" ]; then
      echo "----> $GERRIT_BRANCH"
      # Move to fabric-sdk-java repository and execute end-to-end tests
      rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-java

      WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-java"
      SDK_REPO_NAME=fabric-sdk-java
      git clone git://cloud.hyperledger.org/mirror/$SDK_REPO_NAME $WD
      cd $WD
      if [ "$GERRIT_BRANCH" = "release-1.4" ]; then
          # checkout to master branch till we cut 1.4 branch on sdk-java
          git checkout master
      else
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
