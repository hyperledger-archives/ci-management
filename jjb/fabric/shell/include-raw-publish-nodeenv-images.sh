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

######################
# PUBLISH DOCKER IMAGE
######################
NEXUS_REPOSITORY=nexus3.hyperledger.org:10002
ARCH=$(dpkg --print-architecture | cut -d '-' -f 2)
VERSION=$PUSH_VERSION
# Clone fabric-chaincode-node git repository
clone_Repo() {
    rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-chaincode-node
    WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-chaincode-node"
    REPO_NAME=fabric-chaincode-node
    git clone --single-branch -b $GERRIT_BRANCH https://github.com/hyperledger/$REPO_NAME $WD
    cd $WD && git checkout $GERRIT_BRANCH && git checkout $RELEASE_COMMIT
    # Checkout to the branch and checkout to release commit
    # Provide the value to release commit from Jenkins parameter
    echo "-------> INFO: RELEASE_COMMIT" $RELEASE_COMMIT
}

# error check
err_check() {
    echo "--------> $1 <---------"
    exit 1
}

build_Images() {
        NODE_VER=10.15.2
        nvm install $NODE_VER
        # use nodejs 10.15.2 version
        nvm use --delete-prefix v$NODE_VER --silent
        npm install || err_check "npm install failed"
        npm config set prefix ~/npm || exit 1
        # Build nodeenv image
        npm install -g @microsoft/rush
        rush update
        rush build
        docker images | grep hyperledger
}

publish_Images_Dockerhub() {
    # Publish docker images to hyperledger dockerhub
    docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
    # tag nodeenv release version tag to dockerhub
    docker tag hyperledger/fabric-nodeenv hyperledger/fabric-nodeenv:$ARCH-$VERSION
    # Push nodeenv image to dockerhub
    docker push hyperledger/fabric-nodeenv:$ARCH-$VERSION
    docker images
}

publish_Images_Nexus() {
    # tag nodeenv release version tag to nexus3
    docker tag hyperledger/fabric-nodeenv $NEXUS_REPOSITORY/hyperledger/fabric-nodeenv:$ARCH-$VERSION
    # Push nodeenv image to nexus3
    docker push $NEXUS_REPOSITORY/hyperledger/fabric-nodeenv:$ARCH-$VERSION
    docker images
}

release_nodeenv() {
    echo -e "\033[32m Clone fabric-chaincode-node git repository" "\033[0m"
    clone_Repo
    echo -e "\033[32m Build nodeenv" "\033[0m"
    build_Images
    echo -e "\033[32m Publish images to dockerhub" "\033[0m"
    publish_Images_Dockerhub
    echo -e "\033[32m Publish images to nexus" "\033[0m"
    publish_Images_Nexus
}

release_nodeenv
