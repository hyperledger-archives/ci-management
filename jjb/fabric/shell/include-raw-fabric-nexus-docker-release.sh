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

FABRIC_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-peer | sed 's/.*:\(.*\)]/\1/')

NEXUS_URL=nexus3.hyperledger.org:10002
ORG_NAME="hyperledger/fabric"
# tag fabric images to nexusrepo

dockerTag() {
  for IMAGES in peer orderer couchdb ccenv kafka zookeeper tools; do
    echo "==> $IMAGES"
    echo
    docker tag $ORG_NAME-$IMAGES:latest $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG"
  done
}
# Push docker images to nexus repository

dockerFabricPush() {
  for IMAGES in peer orderer couchdb ccenv kafka zookeeper tools; do
    echo "==> $IMAGES"
    docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG
    echo
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG"
  done
}

# Tag Fabric Docker Images to Nexus Repository
dockerTag

# Push Fabric Docker Images to Nexus Repository
dockerFabricPush

# Listout all docker images Before and After Push to NEXUS
docker images | grep "nexus*"
