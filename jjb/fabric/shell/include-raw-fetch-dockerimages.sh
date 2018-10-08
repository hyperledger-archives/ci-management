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

 # Fetch Go Version from fabric ci.properties file
curl -L https://raw.githubusercontent.com/hyperledger/fabric-baseimage/master/scripts/common/setup.sh > setup.sh
GO_VER=$(cat setup.sh | grep GO_VER= | cut -d "=" -f 2)
echo "-------> GO_VER" $GO_VER
OS_VER=$(dpkg --print-architecture)
echo "------> ARCH: $OS_VER"
export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
export PATH=$GOROOT/bin:$PATH

make docker dependent-images
docker images

BASE_VERSION=$(cat Makefile | grep "^VERSION ?=" | cut -d "=" -f 2 | tr -d ' ')
echo "-------> BASE_VERSION" $BASE_VERSION
ARCH="$(dpkg --print-architecture)"
export ARCH
echo "--------> ARCH" $ARCH

for IMAGES in baseimage baseos kafka zookeeper couchdb; do
docker tag hyperledger/fabric-$IMAGES hyperledger/fabric-$IMAGES:$ARCH-$BASE_VERSION
done

echo "------> Tagged Images list $(docker images)"


# Clone & Checkout to fabric repository
#######################################
FABRIC_REPO_NAME=fabric
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/${FABRIC_REPO_NAME}"
rm -rf $WD
git clone git://cloud.hyperledger.org/mirror/$FABRIC_REPO_NAME $WD
cd $WD && git checkout $GERRI_BRANCH
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC_COMMIT ========> $FABRIC_COMMIT"
echo "FABRIC_COMMIT ------> $FABRIC_COMMIT" >> commit.log
mv commit.log ${WORKSPACE}/gopath/src/github.com/hyperledger/
echo "-------> fabric GERRIT_BRANCH:" $GERRIT_BRANCH

# Modify the Baseimage version
FAB_BASE="$(cat Makefile | grep BASEIMAGE_RELEASE= | cut -d "=" -f 2)"
export FAB_BASE
# Replace FAB_BASE with BASE VERSION
sed -i "s/BASEIMAGE_RELEASE=$FAB_BASE/BASEIMAGE_RELEASE=$BASE_VERSION/g" Makefile
# Gerrit Checkout to Branch

for IMAGES in basic-checks docker release-clean release; do
make $IMAGES
if [ $? != 0 ]; then
echo "------> make $IMAGES failed"
exit 1
fi
done

docker images | grep hyperledger


##############
# JAVAENV
##############

if [[ "$GERRIT_BRANCH" = "master" || "$ARCH" != "s390x" ]]; then

#####################################
# Pull fabric-javaenv Image

NEXUS_URL=nexus3.hyperledger.org:10001
ORG_NAME="hyperledger/fabric"
IMAGE=javaenv

if [ "$GERRIT_BRANCH" = "master" ]; then
export STABLE_VERSION=amd64-1.4.0-stable
export JAVA_ENV_TAG=1.4.0
else
export STABLE_VERSION=amd64-1.3.0-stable
export JAVA_ENV_TAG=1.3.1
fi
docker pull $NEXUS_URL/$ORG_NAME-$IMAGE:$STABLE_VERSION
docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$STABLE_VERSION $ORG_NAME-$IMAGE
docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$STABLE_VERSION $ORG_NAME-$IMAGE:amd64-$JAVA_ENV_TAG
docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$STABLE_VERSION $ORG_NAME-$IMAGE:amd64-latest
######################################
docker images | grep hyperledger/fabric-javaenv || true
else
echo "========> SKIP: javaenv image is not available on $GERRIT_BRANCH or on $ARCH"
fi
echo

##############
# FABRIC_CA
###############

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone git://cloud.hyperledger.org/mirror/$CA_REPO_NAME $WD
cd $WD

echo "-----> fabric-ca GERRIT_BRANCH:" $GERRIT_BRANCH
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "-----> FABRIC_CA_COMMIT : $CA_COMMIT"


# Get Baseimage
CA_BASE="$(cat Makefile | grep "BASEIMAGE_RELEASE =" | cut -d "=" -f 2)"
export CA_BASE
# Replace CA_BASE with BASE VERSION
sed -i "s/BASEIMAGE_RELEASE=$CA_BASE/BASEIMAGE_RELEASE=$BASE_VERSION/g" Makefile


# BUILD DOCKER
make docker
if [ $? != 0 ]; then
echo "------> make docker failed"
exit 1
fi

docker images | grep hyperledger
echo "CA COMMIT ------> $CA_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
