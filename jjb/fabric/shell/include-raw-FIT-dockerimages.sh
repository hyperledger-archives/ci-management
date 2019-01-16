#!/bin/bash -eu
set -o pipefail

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

BASE_WD=${WORKSPACE}/gopath/src/github.com/hyperledger

# Build fabric docker images
############################

# Print last two commits
git -C $BASE_WD/fabric log -n2

if [[ "$GERRIT_BRANCH" = "release-1.0" ]]; then
     for IMAGES in docker-thirdparty peer-docker orderer-docker buildenv testenv tools-docker release-clean release; do
        make -C $BASE_WD/fabric $IMAGES
     done
else
     for IMAGES in docker release-clean release docker-thirdparty; do
         make -C $BASE_WD/fabric $IMAGES
     done
fi

# Build fabric-ca docker image
################################

# Delete fabric-ca repository directory
rm -rf $BASE_WD/fabric-ca
# Clone fabric-ca repisitory
git clone --single-branch -b $GERRIT_BRANCH git://cloud.hyperledger.org/mirror/fabric-ca $BASE_WD/fabric-ca

# Print last two commits
git -C $BASE_WD/fabric-ca log -n2

# Build fabric-ca docker image
make -C $BASE_WD/fabric-ca docker

# List all the docker images
docker images | grep hyperledger
