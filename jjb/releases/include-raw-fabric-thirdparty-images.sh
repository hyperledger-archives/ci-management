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

MARCH=$(go env GOARCH)
DEPENDENT_TAG=$MARCH-$(make -f Makefile -f <(printf 'p:\n\t@echo $(VERSION)\n') p)
echo "DEPENDENT_TAG Images TAG ID is: " $DEPENDENT_TAG
ORG_NAME="hyperledger/fabric"
NEXUS_REPO_URL="nexus3.hyperledger.org:10002"
ARCH=$(dpkg --print-architecture)
echo "----------> ARCH:" $ARCH

dockerBaseImages() {

  # shellcheck disable=SC2043
  for IMAGES in baseimage baseos basejvm; do
    echo "==> $IMAGES"
    docker tag $ORG_NAME-$IMAGES:$DEPENDENT_TAG $NEXUS_REPO_URL/$ORG_NAME-$IMAGES:$DEPENDENT_TAG
    echo "==> $NEXUS_REPO_URL/$ORG_NAME-$IMAGES:$DEPENDENT_TAG"
    docker push $NEXUS_REPO_URL/$ORG_NAME-$IMAGES:$DEPENDENT_TAG
  done
}

#docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
# Push docker images to dockerhub

dockerThirdpartyImage() {

  # shellcheck disable=SC2043
  for IMAGES in couchdb kafka zookeeper; do
    echo "-------> Publish thirdparty Docker images to DockerHub"
    docker push $ORG_NAME-$IMAGES:$DEPENDENT_TAG
    echo
    echo "-------> $ORG_NAME-$IMAGES:$DEPENDENT_TAG"
    echo
    docker tag $ORG_NAME-$IMAGES:$DEPENDENT_TAG $NEXUS_REPO_URL/$ORG_NAME-$IMAGES:$DEPENDENT_TAG
    echo "-------> $NEXUS_REPO_URL/$ORG_NAME-$IMAGES:$DEPENDENT_TAG"
    echo "-------> Publish thirdparty Docker images to Nexus3"
    docker push $NEXUS_REPO_URL/$ORG_NAME-$IMAGES:$DEPENDENT_TAG
  done
}

echo "--------> Publish baseimage to DockerHub"
make install

echo "--------> Publish baseimage to Nexus3
dockerBaseImages

echo "--------> Build Thirdparty Docker images"
make dependent-images

echo "--------> Publish Thirdparty Docker images to DockerHub and Nexus3
dockerThirdpartyImage

# Listout all docker images
docker images | grep "hyperledger*"
