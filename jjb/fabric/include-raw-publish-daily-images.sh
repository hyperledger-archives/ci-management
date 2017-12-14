#!/bin/bash -eu

set -o pipefail

FABRIC_TAG=DAILY_STABLE
CA_TAG=DAILY_STABLE

NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"
# tag fabric images to nexusrepo

dockerTag() {
  for IMAGES in peer orderer ccenv javaenv; do
    echo "==> $IMAGES"
    echo
    docker tag $ORG_NAME-$IMAGES:latest $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG"
  done
}
dockerCaTag() {
  echo
  docker tag $ORG_NAME-ca:latest $NEXUS_URL/$ORG_NAME-ca:$CA_TAG
  echo "==> $NEXUS_URL/$ORG_NAME-ca:$CA_TAG"
}
# Push docker images to nexus repository

dockerFabricPush() {
  for IMAGES in peer orderer ccenv javaenv; do
    echo "==> $IMAGES"
    docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG
    echo
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG"
  done
}

dockerCaPush() {
  docker push $NEXUS_URL/$ORG_NAME-ca:$CA_TAG
  echo
  echo "==> $NEXUS_URL/$ORG_NAME-ca:$CA_TAG"
}

# Tag Fabric Docker Images to Nexus Repository
dockerTag

# Push Fabric Docker Images to Nexus Repository
dockerFabricPush

# Tag Fabric-ca Docker Image to Nexus Repository
dockerCaTag

# Push Fabric-ca docker images to nexus Repository
dockerCaPush

# Listout all docker images Before and After Push to NEXUS
docker images | grep "nexus*"
