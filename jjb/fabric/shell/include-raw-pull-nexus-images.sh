#!/bin/bash -x
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

docker login -u docker -p docker nexus3.hyperledger.org:10001
NEXUS_URL=nexus3.hyperledger.org:10001
ORG_NAME="hyperledger/fabric"
MARCH=$(go env GOARCH)
TAG=$GIT_COMMIT
export CCENV_TAG=${TAG:0:7}
cd ${GOPATH}/src/github.com/hyperledger/fabric || exit
VERSION=$(make -f Makefile -f <(printf 'p:\n\t@echo $(BASE_VERSION)\n') p)
echo "------> BASE_VERSION = $VERSION"

dockerTag() {
  for IMAGES in peer orderer ccenv tools; do
    echo "==> $IMAGES"
    echo
    docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$CCENV_TAG
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$CCENV_TAG $ORG_NAME-$IMAGES
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$CCENV_TAG"
  done
}

# Tag nexus fabric docker images to hyperledger
dockerTag
docker tag $NEXUS_URL/$ORG_NAME-ccenv:$CCENV_TAG $ORG_NAME-ccenv:$MARCH-$VERSION-snapshot-$CCENV_TAG
docker tag $NEXUS_URL/$ORG_NAME-ccenv:$CCENV_TAG $ORG_NAME-ccenv:$MARCH-latest

# Generate list of docker images that 'make docker' produces
docker images | grep "hyperledger"
