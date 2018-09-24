#!/bin/bash -exu
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
export WD=${WORKSPACE}

cd $WD
# checkout to jsdk v1.0.0 release
git checkout tags/v1.0.0
# shellcheck source=/dev/null
source ${WORKSPACE}/src/test/fabric_test_commitlevel.sh

# Clone fabric git repository
#############################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

WD1="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
REPO_NAME=fabric
git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD1
cd $WD1
if [ "$FABRIC_COMMIT" == "latest" ]; then
    echo "Fabric commit is $FABRIC_COMMIT so go with this"
else
    git checkout $FABRIC_COMMIT
    FABRIC_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
    echo "====> FABRIC_COMMIT_LEVEL $FABRIC_COMMIT_LEVEL"
fi
FABRIC_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
echo "====> FABRIC_COMMIT_LEVEL $FABRIC_COMMIT_LEVEL"
# Build fabric Docker images
make docker
if [ $? != 0 ]; then
    echo "--------> make docker failed"
    exit 1
fi
docker images | grep hyperledger

if [ "$GERRIT_BRANCH" = "master" ]; then
    export JAVA_VERSION=amd64-1.4.0-stable
    export JAVA_ENV_TAG=1.4.0
else
    export JAVA_VERSION=amd64-1.3.0-stable
    export JAVA_ENV_TAG=1.3.0
fi

########################
# Pull Javaenv image from nexus and re-tag to hyperledger/fabric-javaenv:$JAVA_VERSION
#######################
docker pull nexus3.hyperledger.org:10001/hyperledger/fabric-javaenv:$JAVA_VERSION
docker tag nexus3.hyperledger.org:10001/hyperledger/fabric-javaenv:$JAVA_VERSION hyperledger/fabric-javaenv:amd64-$JAVA_ENV_TAG
docker tag nexus3.hyperledger.org:10001/hyperledger/fabric-javaenv:$JAVA_VERSION hyperledger/fabric-javaenv:amd64-latest
docker tag nexus3.hyperledger.org:10001/hyperledger/fabric-javaenv:$JAVA_VERSION hyperledger/fabric-javaenv
##########
docker images | grep hyperledger/fabric-javaenv || true

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD2="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone git://cloud.hyperledger.org/mirror/$CA_REPO_NAME $WD2
cd $WD2
if [ "$FABRIC_CA_COMMIT" == "latest" ]; then
    echo "Fabric_CA commit is $FABRIC_COMMIT so go with this"
else
    git checkout $FABRIC_CA_COMMIT
    CA_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
    echo "======> CA_COMMIT_LEVEL $CA_COMMIT_LEVEL"
fi
CA_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
echo "======> CA_COMMIT_LEVEL $CA_COMMIT_LEVEL"

# Build CA Docker Images
make docker-fabric-ca
if [ $? != 0 ]; then
   echo "--------> make docker-fabric-ca failed"
   exit 1
fi
docker images | grep hyperledger

# Move to fabric-sdk-java repository and execute SDK end-to-end tests
export GOPATH=$WD/src/test/fixture

cd $WD/src/test
JAVA_SDK_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
echo "JAVA COMMIT =====> $JAVA_SDK_COMMIT_LEVEL"
chmod +x cirun.sh
source cirun.sh
