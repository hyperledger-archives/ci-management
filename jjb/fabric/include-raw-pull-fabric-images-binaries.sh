#!/bin/bash -eu

set -o pipefail

     if [ -z "${GIT_COMMIT:-}" ]; then
            echo "=====> GIT_COMMIT is unset and no value assigned"
            GIT_COMMIT=$GERRIT_PATCHSET_VERSION
	    echo "=====> GERRIT_PATCHSET_VERSION value (GIT_COMMIT): $GIT_COMMIT"
     else
            GIT_COMMIT=$GIT_COMMIT
	    echo "=====> GIT_COMMIT: $GIT_COMMIT"
     fi

NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"
# tag fabric images
MARCH=$(uname -m)
TAG=$GIT_COMMIT
export CCENV_TAG=${TAG:0:7}
export VERSION=1.1.0-beta

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric && mkdir -p build && cd build

curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-build/linux-amd64-$GIT_COMMIT/hyperledger-fabric-build-linux-amd64-$GIT_COMMIT.tar.gz | tar xz

cp -r bin/ $WORKSPACE/gopath/src/github.com/hyperledger/fabric/release

dockerTag() {
  for IMAGES in peer orderer ccenv javaenv tools; do
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
docker images | grep "hyperledger*"
