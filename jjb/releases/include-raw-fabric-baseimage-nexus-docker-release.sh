#!/bin/bash
set -o pipefail

NEXUS_URL=nexus3.hyperledger.org:10002
ORG_NAME="hyperledger/fabric"
ARCH=$(dpkg --print-architecture)
if [ "$GERRIT_BRANCH" = "release-1.0" ] || [ "$GERRIT_BRANCH" = "release-1.1" ]; then
       ARCH=x86_64
else
      ARCH=$(dpkg --print-architecture)
      echo "----------> ARCH:" $ARCH
fi

# Push docker images to nexus docker repository
dockerBasePush() {

  for IMAGES in baseos basejvm baseimage; do
    echo "==> $IMAGES"
    echo
    docker tag $ORG_NAME-$IMAGES:latest $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$PUSH_VERSION
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$PUSH_VERSION"
    docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$PUSH_VERSION
    echo
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$PUSH_VERSION"
    echo
  done
}

dockerBasePush

# Listout all docker images After push to NEXUS Docker
docker images | grep "hyperledger*"
