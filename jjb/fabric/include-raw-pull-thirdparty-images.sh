#!/bin/bash
set -o pipefail

ORG_NAME="hyperledger/fabric"
# tag fabric images
MARCH=`uname -m`
BASEIMAGE_RELEASE=`cat $WORKSPACE/gopath/src/github.com/hyperledger/fabric/Makefile | grep BASEIMAGE_RELEASE= | cut -d "=" -f 2`
echo "-----> BASEIMAGE_RELEASE: $BASEIMAGE_RELEASE"

dockerTag() {
    for IMAGES in couchdb kafka zookeeper; do
       echo "==> $IMAGES"
       docker pull $ORG_NAME-$IMAGES:$MARCH-$BASEIMAGE_RELEASE
       docker tag $ORG_NAME-$IMAGES:$MARCH-$BASEIMAGE_RELEASE $ORG_NAME-$IMAGES
       echo
    done
}
# Tag Fabric couchdb, kafka and zookeeper docker images
dockerTag

# List out all docker images
docker images | grep "hyperledger*"
