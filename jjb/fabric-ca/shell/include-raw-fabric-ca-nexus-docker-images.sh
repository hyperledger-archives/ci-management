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

ORG_NAME="hyperledger/fabric"
NEXUS_REPO_URL=nexus3.hyperledger.org:10002
# PUSH_VERSION comes from Jenkins environment variable
if [ "$GERRIT_BRANCH" = "release-1.0" ] || [ "$GERRIT_BRANCH" = "release-1.1" ]; then
      ARCH=x86_64
      export ARCH
      echo "----------> ARCH:" $ARCH
else
      ARCH=$(dpkg --print-architecture) # amd64, s390x
      export ARCH
      echo "----------> ARCH:" $ARCH
fi

# tag fabric-ca images

dockerCaTag() {
  for IMAGES in ${IMAGES_LIST[*]}; do
    docker tag $ORG_NAME-$IMAGES:$ARCH-$1 $NEXUS_REPO_URL/$ORG_NAME-$IMAGES:$ARCH-$1
    echo "==> $NEXUS_REPO_URL/$ORG_NAME-$IMAGES:$ARCH-$1"
  done
}
# Push fabric-ca images to nexusrepo

dockerCaPush() {
  for IMAGES in ${IMAGES_LIST[*]}; do
    docker push $NEXUS_REPO_URL/$ORG_NAME-$IMAGES:$ARCH-$1
    echo "==> $NEXUS_REPO_URL/$ORG_NAME-$IMAGES:$ARCH-$1"
  done
}

if [ "$GERRIT_BRANCH" = "release-1.1" ] || [ "$GERRIT_BRANCH" = "release-1.2" ]; then
    IMAGES_LIST=(ca ca-peer ca-tools ca-orderer)
    # Tag & Push Fabric Docker Images to Nexus Repository
    echo "==== Tag Images ===="
    dockerCaTag $PUSH_VERSION
    echo "==== Push Images to Nexus ===="
    dockerCaPush $PUSH_VERSION
 else
    IMAGES_LIST=(ca)
    # Tag & Push Fabric Docker Images to Nexus Repository
    echo "==== Tag Images ===="
    dockerCaTag $PUSH_VERSION
    echo "==== Push Images to Nexus ===="
    dockerCaPush $PUSH_VERSION
 fi

# Listout all docker images Before and After Push to NEXUS
docker images | grep "nexus*"
