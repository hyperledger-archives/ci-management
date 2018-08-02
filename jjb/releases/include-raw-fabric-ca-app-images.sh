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

FABRIC_CA_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-ca | sed 's/.*:\(.*\)]/\1/')
echo "FABRIC Images TAG ID is: " $FABRIC_CA_TAG
echo
ORG_NAME="hyperledger/fabric"

docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
# Push docker images to hyperledger dockerhub repository

dockerCaPush() {
  # shellcheck disable=SC2043
  for IMAGES in ca ca-peer ca-orderer ca-tools; do
    echo "==> $IMAGES"
    docker push $ORG_NAME-$IMAGES:$FABRIC_CA_TAG
    echo
    echo "==> $ORG_NAME-$IMAGES:$FABRIC_CA_TAG"
    echo
  done
}

# Push Fabric Docker Images to hyperledger dockerhub Repository
dockerCaPush

if [ "$GERRIT_BRANCH" = "release-1.0" ]; then
    echo "-------> Publish fabric-ca docker images from $GERRIT_BRANCH"
    docker push $ORG_NAME-ca:$FABRIC_CA_TAG
    echo
    echo "==> $ORG_NAME-ca:$FABRIC_CA_TAG"
    echo
else
    echo "--------> publish ca images from $GERRIT_BRANCH"
    dockerCaPush
fi

# Listout all docker images Before and After Push to NEXUS
docker images | grep "hyperledger*"
