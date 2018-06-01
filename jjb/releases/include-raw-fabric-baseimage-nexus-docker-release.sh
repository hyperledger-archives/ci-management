#!/bin/bash

set -o pipefail

BASE_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-baseimage | sed 's/.*:\(.*\)]/\1/')
echo "======> $BASE_TAG"
NEXUS_URL=nexus3.hyperledger.org:10002
ORG_NAME="hyperledger/fabric"

# Push docker images to nexus docker repository

dockerBasePush() {

  for IMAGES in baseos basejvm baseimage; do
    echo "==> $IMAGES"
    echo
    docker tag $ORG_NAME-$IMAGES:latest $NEXUS_URL/$ORG_NAME-$IMAGES:$BASE_TAG
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$BASE_TAG"
    docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$BASE_TAG
    echo
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$BASE_TAG"
    echo
  done
}

dockerBasePush

# Listout all docker images After push to NEXUS Docker
docker images | grep "hyperledger*"
