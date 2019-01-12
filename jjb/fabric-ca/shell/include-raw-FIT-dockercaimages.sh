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

BASE_WD=${WORKSPACE}/gopath/src/github.com/hyperledger

# Build fabric-ca docker images
###############################
echo -e "\033[32m Build fabric_ca Images \033[0m"

# Print last two commits
git -C $BASE_WD/fabric-ca log -n2

# Build fabric-ca docker image
make -C $BASE_WD/fabric-ca docker-fabric-ca

# Build fabric docker images
############################
echo -e "\033[32m Build fabric docker images \033[0m"

# Delete fabric directory
rm -rf $BASE_WD/fabric

# Clone single branch from gerrit mirro url
echo -e "\033[32m Clone fabric repository \033[0m"
git clone --single-branch -b $GERRIT_BRANCH git://cloud.hyperledger.org/mirror/fabric $BASE_WD/fabric
cd $BASE_WD/fabric

# Checkout to branch
git checkout $GERRIT_BRANCH

# Print last two commits
git log -n2

if ! GO_VER=$(grep GO_VER ci.properties | cut -d "=" -f2); then
    echo "-----> GO_VER not set"
    exit 1
fi
echo -e "\033[32m -------> GO_VER $GO_VER \033[0m"

# export fabric go version
GOROOT=/opt/go/go$GO_VER.linux.amd64
PATH=$GOROOT/bin:$PATH

# Build fabric docker images
make docker
