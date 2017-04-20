#!/bin/bash
set -o pipefail

FABRIC_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-peer | sed 's/.*:\(.*\)]/\1/')
echo "FABRIC Images TAG ID is: " $FABRIC_TAG
echo
ORG_NAME="hyperledger/fabric"

docker login --email=$DOCKER_HUB_EMAIL --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
# Push docker images to nexus repository

dockerFabricPush() {

  for IMAGES in peer orderer couchdb ccenv javaenv kafka zookeeper; do
    echo "==> $IMAGES"
    docker push $ORG_NAME-$IMAGES:$FABRIC_TAG
    echo
    echo "==> $ORG_NAME-$IMAGES:$FABRIC_TAG"
    echo
  done
}

# Push Fabric Docker Images to Nexus Repository
dockerFabricPush

# Listout all docker images Before and After Push to NEXUS
docker images | grep "hyperledger*"
