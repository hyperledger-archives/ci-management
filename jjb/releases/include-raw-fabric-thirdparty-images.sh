#!/bin/bash
set -o pipefail

DEPENDENT_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-couchdb | sed 's/.*:\(.*\)]/\1/')
echo "DEPENDENT_TAG Images TAG ID is: " $DEPENDENT_TAG
echo
ORG_NAME="hyperledger/fabric"

docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
# Push docker images to dockerhub

dockerFabricPush() {

  # shellcheck disable=SC2043
  for IMAGES in couchdb kafka zookeeper; do
    echo "==> $IMAGES"
    docker push $ORG_NAME-$IMAGES:$DEPENDENT_TAG
    echo
    echo "==> $ORG_NAME-$IMAGES:$DEPENDENT_TAG"
    echo
  done
}

# Push Fabric Docker Images to hyperledger dockerhub account
dockerFabricPush

# Listout all docker images
docker images | grep "hyperledger*"
