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
GO_VER=$(cat setup.sh | grep GO_VER= | cut -d "=" -f 2)
[ -z "$GO_VER" ] && echo "-----> Empty GO_VER"
exit 1
# Get ARCH
ARCH=$(dpkg --print-architecture)
echo "------> ARCH: $ARCH"
# Export goroot
export GOROOT=/opt/go/go$GO_VER.linux.$ARCH
export PATH=$GOROOT/bin:$PATH

# Build fabric baseimages and thirdparty images
cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-baseimage
make docker dependent-images

BASE_VERSION=$(cat Makefile | grep "^VERSION ?=" | cut -d "=" -f2 | tr -d '')
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

# Modify the Baseimage version
FAB_BASE="$(cat Makefile | grep "BASEIMAGE_RELEASE=" | cut -d "=" -f2)"
# Replace FAB_BASE with BASE VERSION
sed -i "s/BASEIMAGE_RELEASE=$FAB_BASE/BASEIMAGE_RELEASE=$BASE_VERSION/g" Makefile

# Build docker images, binaries & execute basic-checks
for IMAGES in basic-checks docker release-clean release; do
    make $IMAGES
done

##############
# FABRIC_CA
###############
FABRIC_CA_WD=$WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca
rm -rf $FABRIC_CA_WD
# Clone fabri-ca repository with single branch
git clone --single-branch -b $GERRIT_BRANCH git://cloud.hyperledger.org/mirror/fabric-ca $FABRIC_CA_WD
cd $FABRIC_CA_WD

# Print last two commits
git log -n2

# Get Baseimage version
CA_BASE="$(cat Makefile | grep "BASEIMAGE_RELEASE =" | cut -d "=" -f2)"

# Replace CA_BASE with BASE VERSION
sed -i "s/BASEIMAGE_RELEASE=$CA_BASE/BASEIMAGE_RELEASE=$BASE_VERSION/g" Makefile

# Build fabric-ca docker images
make docker

# List all docker images
docker images | grep hyperledger
