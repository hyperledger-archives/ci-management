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

container_list=(orderer peer0.org1 peer0.org2 ca0 ca1)
# error check
err_and_exit() {
    echo -e "\033[31mERROR!!! $*" "\033[0m"
    for container in ${container_list[*]}; do
        docker logs $container.example.com >&$container.log || true
    done
    docker logs couchdb >&couchdb.log
    grep /w/workspace/${JOB_NAME}/gopath/src/github.com/hyperledger/fabric-sdk-node/test/temp/debug.log >&debug.log
    exit 1
}

generatecerts() {
    # Generate crypto material before running the tests
    if [[ $arch == "s390x" ]]; then
        # Run the s390x gulp task
        gulp install-and-generate-certs-s390 || err_and_exit "gulp install and generation of test certificates failed"
    else
        # Run the amd64 gulp task
        gulp install-and-generate-certs || err_and_exit "gulp install and generation of test certificates failed"
    fi
}
function clearContainers() {
    container_ids=$(docker ps -aq)
    if [[ -z $container_ids || $container_ids == " " ]]; then
        echo "---- No containers available for deletion ----"
    else
        docker rm -f $container_ids || true
        echo "---- Docker containers after cleanup ----"
        docker ps -a
    fi
}

function removeUnwantedImages() {
    docker_image_ids=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
    if [[ -z $docker_image_ids || $docker_image_ids == " " ]]; then
        echo "---- No images available for deletion ----"
    else
        docker rmi -f $docker_image_ids || true
        echo "---- Docker images after cleanup ----"
        docker images
    fi
}

# RUN END-to-END Test
#####################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node
sdk_node_wd="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node"
arch=$(dpkg --print-architecture)
sdk_repo_name=fabric-sdk-node
git clone git://cloud.hyperledger.org/mirror/$sdk_repo_name $sdk_node_wd
cd $sdk_node_wd
git checkout $GERRIT_BRANCH
sdk_node_commit=$(git log -1 --pretty=format:"%h")
echo "------> sdk_node_commit: $sdk_node_commit"
echo "sdk_node_commit=======> $sdk_node_commit" >>${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
echo "======> ARCH: $arch"

set +e
if [[ $arch == "amd64" ]]; then
    # Install nvm to install multi node versions
    wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
    export NVM_DIR=$HOME/.nvm
    # shellcheck source=/dev/null
    source $NVM_DIR/nvm.sh # Setup environment for running nvm
else
    source /etc/profile.d/nvmrc.sh
fi
set -e

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-chaincode-node
cc_node_wd="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-chaincode-node"
repo_name=fabric-chaincode-node
git clone git://cloud.hyperledger.org/mirror/$repo_name $cc_node_wd
if [[ $GERRIT_BRANCH == "master" || $GERRIT_BRANCH == "release-1.4" ]]; then
    cd $cc_node_wd
    # Checkout to GERRIT_BRANCH
    git checkout $GERRIT_BRANCH
    node_ver10=10.15.3
    echo -e "\033[1;32m Intalling Node $node_ver10\033[0m"
    nvm install "$node_ver10"
    nvm use --delete-prefix v$node_ver10 --silent
    npm install || err_and_exit "npm install failed"
    npm config set prefix ~/npm
    echo -e "\033[32m npm version" "\033[0m"
    npm -v
    echo -e "\033[32m node version" "\033[0m"
    node -v
    npm install -g gulp
    cd $sdk_node_wd
    npm install || err_and_exit "npm install failed"
    npm config set prefix ~/npm
    echo -e "\033[32m npm version" "\033[0m"
    npm -v
    echo -e "\033[32m node version" "\033[0m"
    node -v
    npm install -g gulp
    echo "#################"
    echo " Run gulp tests"
    echo "#################"

    if [[ $GERRIT_BRANCH == "master" ]]; then
        cd $cc_node_wd
        # Build nodeenv image
        gulp docker-image-build
        docker images | grep hyperledger && docker ps -a
        cd $sdk_node_wd
        generatecerts
        echo -e "\n------> Starting gulp end-to-end tests for node $node_ver10\n"
        # The export of this variable is a temporary fix until we can isolate
        # a failure in the SoftHSM library which applies only to master
        export PKCS11_TESTS=false
        gulp run-test-merge || err_and_exit "gulp end-2-end tests failed for node $node_ver10"
    else
        cd $sdk_node_wd
        echo -e "\n------> Starting gulp end-to-end tests for node $node_ver10\n"
        gulp run-end-to-end || err_and_exit "gulp end-2-end tests failed for node $node_ver10"
    fi
        rm -rf node_modules package-lock.json
fi

cd $cc_node_wd
# remove tmp/hfc and hfc-key-store data
rm -rf node_modules package-lock.json
clearContainers
removeUnwantedImages
