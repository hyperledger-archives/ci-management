#!/bin/bash
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

# Clone fabric-ca git repository
################################
ORG_NAME="hyperledger/fabric"
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone git://cloud.hyperledger.org/mirror/$CA_REPO_NAME $WD
cd $WD || exit
git checkout $GERRIT_BRANCH && git checkout $RELEASE_COMMIT
echo "------> RELEASE_COMMIT" $RELEASE_COMMIT
GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
export GO_VER
OS_VER=$(dpkg --print-architecture)
echo "------> OS_VER: $OS_VER"
export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
export PATH=$GOROOT/bin:$PATH
echo "------> GO_VER" $GO_VER
ARCH=$(go env GOARCH)
echo "------> ARCH" $ARCH

# Build ca images
make docker

# Tag ca images
docker tag $ORG_NAME-ca $ORG_NAME-ca:$ARCH-$PUSH_VERSION

docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
# Push docker images to hyperledger dockerhub repository

dockerCaPush() {
  # shellcheck disable=SC2043
  for IMAGES in ca; do
    echo "==> $IMAGES"
    docker push $ORG_NAME-$IMAGES:$ARCH-$1
    echo
    echo "==> $ORG_NAME-$IMAGES:$ARCH-$1"
    echo
  done
}
# list docker images
docker images | grep hyperledger

# Push Fabric Docker Images to hyperledger dockerhub Repository
dockerCaPush $PUSH_VERSION
