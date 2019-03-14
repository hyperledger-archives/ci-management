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

# RUN END-to-END Test
#####################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node

SDK_NODE_WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node"
SDK_REPO_NAME=fabric-sdk-node
git clone git://cloud.hyperledger.org/mirror/$SDK_REPO_NAME $SDK_NODE_WD
cd $SDK_NODE_WD
git checkout $GERRIT_BRANCH

# error check
err_check() {
echo "--------> $1 <---------"
exit 1
}

SDK_NODE_COMMIT=$(git log -1 --pretty=format:"%h")
echo "------> SDK_NODE_COMMIT : $SDK_NODE_COMMIT"
echo "SDK_NODE_COMMIT=======> $SDK_NODE_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log

ARCH=$(dpkg --print-architecture)
echo "======" $ARCH
if [[ "$ARCH" = "amd64" || "$ARCH" = "ppc64le" ]]; then
   # Install nvm to install multi node versions
   wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
   export NVM_DIR=$HOME/.nvm
   # shellcheck source=/dev/null
   source $NVM_DIR/nvm.sh # Setup environment for running nvm
else
   source /etc/profile.d/nvmrc.sh
fi

figlet -w 132 'SDK-NODE TESTS'
echo "-------> Install NodeJS"

# Checkout to GERRIT_BRANCH
if [[ "$GERRIT_BRANCH" = *"release-1.0"* ]]; then # Only on release-1.0 branch
    NODE_VER=6.9.5
    echo "------> Use $NODE_VER for release-1.0 branch"
    nvm install $NODE_VER
    # use nodejs 6.9.5 version
    nvm use --delete-prefix v$NODE_VER --silent
elif [[ "$GERRIT_BRANCH" = *"release-1.1"* || "$GERRIT_BRANCH" = *"release-1.2"* ]]; then # only on release-1.2 or release-1.1 branches
    NODE_VER=8.9.4
    echo "------> Use $NODE_VER for release-1.1 and release-1.2 branches"
    nvm install $NODE_VER
    # use nodejs 8.9.4 version
    nvm use --delete-prefix v$NODE_VER --silent
elif [[ "$GERRIT_BRANCH" = "master" ]]; then
    echo -e "\033[32m Build Chaincode-nodeenv-image" "\033[0m"
    rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-chaincode-node
    WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-chaincode-node"
    REPO_NAME=fabric-chaincode-node
    git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
    cd $WD || exit
    NODE_VER=8.11.3
    nvm install $NODE_VER
    # use nodejs 8.11.3 version
    nvm use --delete-prefix v$NODE_VER --silent
    npm install || err_check "npm install failed"
    npm config set prefix ~/npm || exit 1
    npm install -g gulp || exit 1
    # Build nodeenv image
    gulp docker-image-build
    docker images | grep hyperledger && docker ps -a
else
    NODE_VER=8.11.3
    echo "------> Use $NODE_VER for master"
    nvm install $NODE_VER
    # use nodejs 8.11.3 version
    nvm use --delete-prefix v$NODE_VER --silent
    echo "npm version ======>"
    npm -v
    echo "node version =======>"
    node -v
fi

cd $SDK_NODE_WD
npm install || err_check "npm install failed"
npm config set prefix ~/npm || exit 1
npm install -g gulp || exit 1

generatecerts () {
# Generate crypto material before running the tests
if [ $ARCH == "s390x" ]; then
# Run the s390x gulp task
    gulp install-and-generate-certs-s390 || err_check "ERROR!!! gulp install and generation of test certificates failed"
else
# Run the amd64 gulp task
    gulp install-and-generate-certs || err_check "ERROR!!! gulp install and generation of test certificates failed"
fi
}

echo "#################"
echo " Run gulp tests"
echo "#################"

case $GERRIT_BRANCH in
"release-1.0" | "release-1.1" | "release-1.2" | "release-1.3")
gulp || err_Check "ERROR!!! gulp failed"
gulp ca || err_Check "ERROR!!! gulp ca failed"
echo "------> Run node Headless & Integration tests"
gulp test || err_Check "ERROR!!! gulp test failed"
;;
release-1.4)
echo "------> Starting gulp end-to-end tests"
gulp run-end-to-end || err_check "ERROR!!! gulp end-2-end tests failed"
;;
*)
generatecerts
echo "------> Starting gulp end-to-end tests"
gulp run-end-to-end || err_check "ERROR!!! gulp end-2-end tests failed"
;;
esac

function clearContainers () {
    CONTAINER_IDS=$(docker ps -aq)
        if [ -z "$CONTAINER_IDS" ] || [ "$CONTAINER_IDS" = " " ]; then
                echo "---- No containers available for deletion ----"
        else
                docker rm -f $CONTAINER_IDS || true
                echo "---- Docker containers after cleanup ----"
                docker ps -a
        fi
}

function removeUnwantedImages() {
        DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
        if [ -z "$DOCKER_IMAGE_IDS" ] || [ "$DOCKER_IMAGE_IDS" = " " ]; then
                echo "---- No images available for deletion ----"
        else
                docker rmi -f $DOCKER_IMAGE_IDS || true
                echo "---- Docker images after cleanup ----"
                docker images
        fi
}

cd $WD
# remove tmp/hfc and hfc-key-store data
rm -rf node_modules package-lock.json || true
clearContainers
removeUnwantedImages
