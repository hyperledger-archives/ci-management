#!/bin/bash -eu

set -o pipefail

NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"
# tag fabric images
MARCH=$(shell uname -m)
VERSION=`cat Makefile | grep PREV_VERSION | awk '{print $3 }'`
TAG=$GIT_COMMIT
export CCENV_TAG=${TAG:0:7}

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/release

curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/linux-amd64-$GIT_COMMIT/hyperledger-fabric-linux-amd64.$GIT_COMMIT.tar.gz | tar xz

dockerTag() {
  for IMAGES in peer orderer couchdb ccenv javaenv kafka zookeeper tools; do
    echo "==> $IMAGES"
    echo
    docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT $ORG_NAME-$IMAGES
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT"
  done
}
# Tag Fabric Nexus docker images to hyperledger
dockerTag
docker tag $NEXUS_URL/$ORG_NAME-ccenv:$GIT_COMMIT $ORG_NAME-ccenv:$MARCH-$VERSION-snapshot-$CCENV_TAG

# Listout all docker images
docker images | grep "nexus*"
docker images | grep "hyperledger*"
