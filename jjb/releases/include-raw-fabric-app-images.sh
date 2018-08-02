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

FABRIC_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-peer | sed 's/.*:\(.*\)]/\1/')
echo "FABRIC Images TAG ID is: " $FABRIC_TAG
echo
ORG_NAME="hyperledger/fabric"

docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
# Push docker images to nexus repository

#TODO: this is a temporary change to push 1.0.x thirdparty images

docker_Fabric_Thirdparty_Push() {

  # shellcheck disable=SC2043
  for IMAGES in kafka zookeeper couchdb javaenv; do
    echo "==> $IMAGES"
    docker push $ORG_NAME-$IMAGES:$FABRIC_TAG
    echo
    echo "==> $ORG_NAME-$IMAGES:$FABRIC_TAG"
    echo
  done
}

docker_Fabric_Push() {

  # shellcheck disable=SC2043
  for IMAGES in peer orderer ccenv tools; do
    echo "==> $IMAGES"
    docker push $ORG_NAME-$IMAGES:$FABRIC_TAG
    echo
    echo "==> $ORG_NAME-$IMAGES:$FABRIC_TAG"
    echo
  done
}

if [[ "$GERRIT_BRANCH" == "release-1.2" || "$GERRIT_BRANCH" == "master" ]]; then
     echo "-----> Pushing fabric docker images from $GERRIT_BRANCH branch"
     docker_Fabric_Push
elif [[ "$GERRIT_BRANCH" == "release-1.1" ]]; then
     echo "-------> GERRIT_BRANCH" $GERRIT_BRANCH
     for IMAGES in peer orderer ccenv tools javaenv; do
         echo "----------> IMAGES: $IMAGES"
         docker push $ORG_NAME-$IMAGES:$FABRIC_TAG
         echo
         echo "----------> $ORG_NAME-$IMAGES:$FABRIC_TAG"
     done
else
     # Push Fabric & Thirdparty Docker Images from release branch
     echo "-----> Pushing fabric and thirdparty docker images from release-1.0 branch"
     docker_Fabric_Push
     docker_Fabric_Thirdparty_Push
fi
# Listout all the docker images Before and After Push
docker images | grep "hyperledger*"
