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

ORG_NAME="hyperledger/fabric"
NEXUS_REPO_URL=nexus3.hyperledger.org:10002
if [ "$GERRIT_BRANCH" = "release-1.0" ] || [ "$GERRIT_BRANCH" = "release-1.1" ]; then
      ARCH=x86_64
      export ARCH
      echo "----------> ARCH:" $ARCH
else
      ARCH=$(dpkg --print-architecture) # amd64, s390x
      export ARCH
      echo "----------> ARCH:" $ARCH
fi
# tag fabric images to nexusrepo

dockerTag() {
  for IMAGES in ${IMAGES_LIST[*]}; do
    docker tag $ORG_NAME-$IMAGES $NEXUS_REPO_URL/$ORG_NAME-$IMAGES:$ARCH-$1
    echo -e "\033[1m==> $NEXUS_REPO_URL/$ORG_NAME-$IMAGES:$ARCH-$1\033[0m"
  done
}
# Push fabric images to nexus repository

docker_Fabric_Push() {
  for IMAGES in ${IMAGES_LIST[*]}; do
    docker push $NEXUS_REPO_URL/$ORG_NAME-$IMAGES:$ARCH-$1
    echo -e "\033[1m==> $NEXUS_REPO_URL/$ORG_NAME-$IMAGES:$ARCH-$1\033[0m"
  done
}

if [[ "$GERRIT_BRANCH" = "release-1.0" ]]; then
   IMAGES_LIST=(peer orderer ccenv tools zookeeper kafka couchdb javaenv)
   # Tag & Push Fabric Docker Images to Nexus Repository
   echo "==== Tag Images ===="
   dockerTag $PUSH_VERSION
   echo "==== Push Images to Nexus ===="
   docker_Fabric_Push $PUSH_VERSION
elif [[ "$GERRIT_BRANCH" = "release-1.1" ]]; then
   IMAGES_LIST=(peer orderer ccenv tools javaenv)
   # Tag & Push Fabric Docker Images to Nexus Repository
   echo "==== Tag Images ===="
   dockerTag $PUSH_VERSION
   echo "==== Push Images to Nexus ===="
   docker_Fabric_Push $PUSH_VERSION
elif [[ "$GERRIT_BRANCH" = "master" ]]; then
   IMAGES_LIST=(baseos peer orderer ccenv tools)
   # Tag & Push Fabric Docker Images to Nexus Repository
   echo "==== Tag Images ===="
   dockerTag $PUSH_VERSION
   echo "==== Push Images to Nexus ===="
   docker_Fabric_Push $PUSH_VERSION
else
   IMAGES_LIST=(peer orderer ccenv tools)
   # Tag & Push Fabric Docker Images to Nexus Repository
   echo "==== Tag Images ===="
   dockerTag $PUSH_VERSION
   echo "==== Push Images to Nexus ===="
   docker_Fabric_Push $PUSH_VERSION
fi

# Listout all docker images Before and After Push to NEXUS
docker images | grep "nexus*"
