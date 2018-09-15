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
ARCH=$(go env GOARCH)
TAG=$GIT_COMMIT
export CCENV_TAG=${TAG:0:7}
cd ${GOPATH}/src/github.com/hyperledger/fabric || exit
VERSION=$(make -f Makefile -f <(printf 'p:\n\t@echo $(BASE_VERSION)\n') p)
echo "------> BASE_VERSION = $VERSION"

dockerTag() {
  for IMAGES in peer orderer ccenv tools ; do
    echo "==> $IMAGES"
    echo
    docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$CCENV_TAG
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$CCENV_TAG $ORG_NAME-$IMAGES
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$CCENV_TAG"
  done
}

# Tag nexus fabric docker images to hyperledger
dockerTag
docker tag $NEXUS_URL/$ORG_NAME-ccenv:$CCENV_TAG $ORG_NAME-ccenv:$ARCH-$VERSION-snapshot-$CCENV_TAG
docker tag $NEXUS_URL/$ORG_NAME-ccenv:$CCENV_TAG $ORG_NAME-ccenv:$ARCH-latest

# Generate list of docker images that 'make docker' produces
docker images | grep "hyperledger"

if [[ "$GERRIT_BRANCH" != "master" || "$ARCH" = "s390x" ]]; then

       echo "========> SKIP: javaenv image is not available on $GERRIT_BRANCH or on $ARCH"
else
       #####################################
       # Pull fabric-javaenv Image

       NEXUS_URL=nexus3.hyperledger.org:10001
       ORG_NAME="hyperledger/fabric"
       IMAGE=javaenv
       : ${STABLE_VERSION:=amd64-1.3.0-stable}
       docker pull $NEXUS_URL/$ORG_NAME-$IMAGE:$STABLE_VERSION
       docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$STABLE_VERSION $ORG_NAME-$IMAGE
       docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$STABLE_VERSION $ORG_NAME-$IMAGE:amd64-1.3.0
       docker tag $NEXUS_URL/$ORG_NAME-$IMAGE:$STABLE_VERSION $ORG_NAME-$IMAGE:amd64-latest
       ######################################
       docker images | grep hyperledger/fabric-javaenv || true
fi
echo
