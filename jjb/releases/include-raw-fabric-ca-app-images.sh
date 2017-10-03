#!/bin/bash
set -o pipefail

FABRIC_CA_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-ca | sed 's/.*:\(.*\)]/\1/')
echo "FABRIC Images TAG ID is: " $FABRIC_CA_TAG
echo
ORG_NAME="hyperledger/fabric"

docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
# Push docker images to nexus repository

dockerCaPush() {

  # shellcheck disable=SC2043
  for IMAGES in ca; do
    echo "==> $IMAGES"
    docker push $ORG_NAME-$IMAGES:$FABRIC_CA_TAG
    echo
    echo "==> $ORG_NAME-$IMAGES:$FABRIC_CA_TAG"
    echo
  done
}

# Push Fabric Docker Images to Nexus Repository
dockerCaPush

# Listout all docker images Before and After Push to NEXUS
docker images | grep "hyperledger*"
