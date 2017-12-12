#!/bin/bash -eu
set -o pipefail

# RUN END-to-END Tests
######################

NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"
# tag fabric images
MARCH=$(uname -m)
TAG=$GIT_COMMIT
export CCENV_TAG=${TAG:0:7}
export VERSION=1.1.0-alpha

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

WD="${GOPATH}/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples

git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$REPO_NAME $WD
cd $WD

curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/linux-amd64-$GIT_COMMIT/hyperledger-fabric-linux-amd64-$GIT_COMMIT.tar.gz | tar xz

cd first-network
export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH
# Execute below tests
echo
echo "======> DEFAULT CHANNEL <======"

echo y | ./byfn.sh -m down
echo y | ./byfn.sh -m generate
echo y | ./byfn.sh -m up -t 10
echo y | ./byfn.sh -m down

echo
echo "======> CUSTOM CHANNEL <======="

echo y | ./byfn.sh -m generate -c fabricrelease
echo y | ./byfn.sh -m up -c fabricrelease -t 10
echo y | ./byfn.sh -m down


echo
echo "======> CouchDB tests <======="

echo y | ./byfn.sh -m generate -c couchdbtest
echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 10
echo y | ./byfn.sh -m down
