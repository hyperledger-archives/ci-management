#!/bin/bash

set -o pipefail

ORG_NAME="hyperledger/fabric"
# tag fabric images
MARCH=`uname -m`
VERSION=$MARCH-1.1.0-preview

dockerTag() {
  for IMAGES in couchdb kafka zookeeper; do
    echo "==> $IMAGES"
    echo
    docker pull $ORG_NAME-$IMAGES:$VERSION
    docker tag $ORG_NAME-$IMAGES:$VERSION $ORG_NAME-$IMAGES
  done
}
# Tag Fabric couchdb, kafka and zookeeper docker images to hyperledger
dockerTag

# Listout all docker images
docker images | grep "hyperledger*"
