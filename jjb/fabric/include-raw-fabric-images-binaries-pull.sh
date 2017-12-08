#!/bin/bash -eu

set -o pipefail

NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"
# tag fabric images
MARCH=$(shell uname -m)
cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric
VERSION=`cat Makefile | grep PREV_VERSION | awk '{print $3 }'`
cd -
cd $WORKSPACE/github/hyperledger/fabric/release

curl https://nexus.hyperledger.org/content/repositories/snapshots/org/hyperledger/fabric/hyperledger-fabric/linux-amd64-DAILY_STABLE-SNAPSHOT/hyperledger-fabric-linux-amd64.DAILY_STABLE.tar.gz | tar xz

dockerTag() {
  for IMAGES in peer orderer couchdb ccenv javaenv kafka zookeeper tools; do
    echo "==> $IMAGES"
    echo
    docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT $ORG_NAME-$IMAGES
    docker tag $NEXUS_URL/$ORG_NAME-ccenv:$GIT_COMMIT $ORG_NAME-$IMAGES:$MARCH-$VERSION-snapshot-$GIT_COMMIT
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT"
  done
}
# Tag Fabric Nexus docker images to hyperledger
dockerTag

# Listout all docker images
docker images | grep "nexus*"
docker images | grep "hyperledger*"
