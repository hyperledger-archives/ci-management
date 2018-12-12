#!/bin/bash -eu
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

echo "=========>Build FABRIC_CA Image<=========="
cd $GOPATH/src/github.com/hyperledger/fabric-ca
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "CA_COMMIT ===========> $CA_COMMIT" >> commit.log
echo "-----> FABRIC_CA_COMMIT : $CA_COMMIT"
mv commit.log ${WORKSPACE}/gopath/src/github.com/hyperledger/
make docker-fabric-ca
if [ $? != 0 ]; then
   echo "------> make docker failed"
   exit 1
fi
docker images | grep hyperledger

if [[ "$GERRIT_BRANCH" = "master" || "$GERRIT_BRANCH" = "release-1.4" || "$GERRIT_BRANCH" = "release-1.3" || "$ARCH" != "s390x" ]]; then

       #####################################
       # Pull fabric-javaenv Image

       NEXUS_URL=nexus3.hyperledger.org:10001
       ORG_NAME="hyperledger/fabric"
       IMAGE=javaenv
       if [ "$GERRIT_BRANCH" = "master" ]; then
          export JAVA_ENV_VERSION=amd64-2.0.0-stable
          export JAVA_ENV_TAG=2.0.0
       elif [ "$GERRIT_BRANCH" = "release-1.4" ]; then
          export JAVA_ENV_VERSION=amd64-1.4.0-stable
          export JAVA_ENV_TAG=1.4.0
       else
          export JAVA_ENV_VERSION=amd64-1.3.1-stable
          export JAVA_ENV_TAG=1.3.1
       fi
       docker pull $NEXUS_URL/$ORG_NAME-$IMAGE:$JAVA_ENV_VERSION
       docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$JAVA_ENV_VERSION $ORG_NAME-$IMAGE
       docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$JAVA_ENV_VERSION $ORG_NAME-$IMAGE:amd64-$JAVA_ENV_TAG
       docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$JAVA_ENV_VERSION $ORG_NAME-$IMAGE:amd64-latest
       ######################################
       docker images | grep hyperledger/fabric-javaenv || true
else
       echo "========> SKIP: javaenv image is not available on $GERRIT_BRANCH or on $ARCH"
fi

# Clone fabric repository
echo "========>Cloning Fabric<=========="
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
REPO_NAME=fabric
git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
cd $WD || exit

# export fabric go version
GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
export GOROOT=/opt/go/go$GO_VER.linux.amd64
export PATH=$GOROOT/bin:$PATH
echo "----> GO_VER" $GO_VER
set +e

BRANCH_NAME=$(echo $GERRIT_BRANCH | grep 'release-')
echo "-----> $BRANCH_NAME"
if [ ! -z "$BRANCH_NAME" ]; then
      echo "-----> Checkout to $GERRIT_BRANCH branch"
      git checkout $GERRIT_BRANCH
fi
set -e
echo "-----> $GERRIT_BRANCH"
git checkout $GERRIT_BRANCH
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "-----> FABRIC_COMMIT : $FABRIC_COMMIT"
echo "FABRIC_COMMIT ===========> $FABRIC_COMMIT" >> commit.log

make docker
if [ $? != 0 ]; then
   echo "-------> make docker failed"
   exit 1
fi
docker images | grep hyperledger
