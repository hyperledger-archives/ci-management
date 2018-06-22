#!/bin/bash
set -o pipefail

ARCH=$(go env GOARCH)
FABRIC_CA_TAG=$ARCH-1.2.0-rc1
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

# Listout all docker images Before and After Push to NEXUS
docker images | grep "hyperledger*"
