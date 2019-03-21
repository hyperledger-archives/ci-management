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

 # Fetch Go Version from fabric ci.properties file
curl -L https://raw.githubusercontent.com/hyperledger/fabric-baseimage/master/scripts/common/setup.sh > setup.sh
eval "$(grep GO_VER= setup.sh)"
if [ -z "$GO_VER" ]; then
   echo "-----> Empty GO_VER"
   exit 1
fi
echo "GO_VER="$GO_VER
# Get ARCH
ARCH=$(dpkg --print-architecture)
echo "------> ARCH: $ARCH"
# Export goroot
export GOROOT=/opt/go/go$GO_VER.linux.$ARCH
export PATH=$GOROOT/bin:$PATH

# Build fabric baseimages and thirdparty images
cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-baseimage
make docker dependent-images

BASE_VERSION=$(cat Makefile | grep "^VERSION ?=" | cut -d "=" -f2 | tr -d '[:space:]')
echo "-------> BASE_VERSION" $BASE_VERSION

# Tag images to $ARCH-$BASE_VERSION
for IMAGES in baseimage baseos kafka zookeeper couchdb; do
   docker tag hyperledger/fabric-$IMAGES hyperledger/fabric-$IMAGES:$ARCH-$BASE_VERSION
done

# Clone & Checkout to fabric repository
#######################################
FABRIC_WD=$WORKSPACE/gopath/src/github.com/hyperledger/fabric
rm -rf $FABRIC_WD
# Clone fabric repository
git clone --single-branch -b $GERRIT_BRANCH git://cloud.hyperledger.org/mirror/fabric $FABRIC_WD
cd $FABRIC_WD

# Checkout to branch
git checkout $GERRIT_BRANCH

# Print last two commits
git log -n2

# Override value for BASEIMAGE_RELEASE in fabric Makefile with BASE VERSION
# Build docker images, binaries & execute basic-checks
echo "######################"
echo -e "\033[1m B U I L D - F A B R I C\033[0m"
echo "######################"
echo
for IMAGES in basic-checks docker release-clean release; do
   make BASEIMAGE_RELEASE=$BASE_VERSION $IMAGES
done

echo "#######################"
echo -e "\033[1m B U I L D - F A B R I C-C A\033[0m"
echo "#######################"
echo
FABRIC_CA_WD=$WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca
rm -rf $FABRIC_CA_WD
# Clone fabric-ca repository with single branch
git clone --single-branch -b $GERRIT_BRANCH git://cloud.hyperledger.org/mirror/fabric-ca $FABRIC_CA_WD
cd $FABRIC_CA_WD

# Print last two commits
git log -n2

# Override value for BASEIMAGE_RELEASE in fabric-ca Makefile with BASE VERSION
# Build fabric-ca docker images
make BASEIMAGE_RELEASE=$BASE_VERSION docker

# List all docker images
docker images | grep hyperledger
