#!/bin/bash
set -o pipefail

MARCH=$(go env GOARCH)
DEPENDENT_TAG=$MARCH-$(make -f Makefile -f <(printf 'p:\n\t@echo $(VERSION)\n') p)
echo "DEPENDENT_TAG Images TAG ID is: " $DEPENDENT_TAG
NEXUS_URL=nexus3.hyperledger.org:10002
ORG_NAME="hyperledger/fabric"

# Push docker images to nexus docker repository

dockerThirdPartyPush() {

  for IMAGES in couchdb kafka zookeeper; do
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

dockerThirdPartyPush

# Listout all docker images After push to NEXUS Docker
docker images | grep "hyperledger*"
