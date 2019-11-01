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
    if [[ "$GERRIT_BRANCH" = "master" && "$ARCH" = "s390x" ]]; then
        pull_kafkazookeeper
    else
        make docker-thirdparty
    fi

    # Build fabric images with $PUSH_VERSION tag
    for IMAGES in docker release-clean "$@"; do
        echo -e "\033[1m----------> $IMAGES\033[0m"
        make $IMAGES PROJECT_VERSION=$PUSH_VERSION
    done

    echo
    echo "----------> List all fabric docker images"
    docker images | grep hyperledger
}

pull_kafkazookeeper() {
    for image in kafka zookeeper; do
        docker pull hyperledger/fabric-$image:s390x-0.4.17
        docker tag hyperledger/fabric-$image:s390x-0.4.17 hyperledger/fabric-$image
    done
}

# Execute release-all target on x arch
ARCH=$(go env GOARCH)

if [ "$ARCH" = "s390x" ]; then
    echo "---------> ARCH:" $ARCH
    build_Fabric dist
else
    echo "---------> ARCH:" $ARCH
    build_Fabric dist-all
fi

# Most recent system info
df -h
