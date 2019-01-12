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


build_Fabric_Ca() {
    FABRIC_CA_WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
    echo -e "\033[32m === Clone fabric-ca repository ===  \033[0m"
    rm -rf $FABRIC_CA_WD

    # Clone fabric-ca repository with specific branch and depth=1
    git clone --single-branch -b $GERRIT_BRANCH --depth=2 git://cloud.hyperledger.org/mirror/fabric-ca $FABRIC_CA_WD
    cd $FABRIC_CA_WD
    git checkout $GERRIT_BRANCH
    echo "--------> $GERRIT_BRANCH"

    # Print last two commits
    git log -n2

    echo -e "\033[32m ==== Build fabric-ca docker images ==== \033[0m"
    for IMAGES in docker-fabric-ca $2 release-clean $1; do
        # Build docker images with PROJECT_VERSION
        # Get the PUSH_VERSION from Jenkins Enviornment Variable
        make $IMAGES PROJECT_VERSION=$PUSH_VERSION
    done
}

build_Fabric() {
    FABRIC_WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
    rm -rf $FABRIC_WD
    # Clone fabric repository with specific branch and depth=1
    git clone --single-branch -b $GERRIT_BRANCH --depth=2 git://cloud.hyperledger.org/mirror/fabric $FABRIC_WD
    cd $FABRIC_WD

    # Checkout to Branch
    git checkout $GERRIT_BRANCH

    # print last two commits
    git log -n2

    # Pull thirdparty images
    make docker-thirdparty

    # Build fabric images with $PUSH_VERSION tag
    for IMAGES in docker release-clean $1; do
        make $IMAGES PROJECT_VERSION=$PUSH_VERSION
    done

    echo
    echo "----------> List all fabric docker images"
    docker images | grep hyperledger
}

# Execute release-all target on x arch
ARCH=$(go env GOARCH)

if [ "$ARCH" = "s390x" ]; then
    echo "---------> ARCH:" $ARCH
    build_Fabric_Ca release
    build_Fabric dist
else
    echo "---------> ARCH:" $ARCH
    build_Fabric_Ca dist-all docker-fvt
    build_Fabric dist-all
fi
