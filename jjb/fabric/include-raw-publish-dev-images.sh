#!/bin/bash -eu
set -o pipefail

cd gopath/src/github.com/hyperledger/fabric
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC_COMMIT ===========> $FABRIC_COMMIT" >> commit.log
mv commit.log ${WORKSPACE}/gopath/src/github.com/hyperledger/
make docker && docker images | grep hyperledger

# Clone fabric-ca git repository
##################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$CA_REPO_NAME $WD
cd $WD
CA_COMMIT=$(git log -1 --pretty=format:"%h")
make docker && docker images | grep hyperledger
echo "CA COMMIT ========> $CA_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log

######################
#publish docker images
######################

NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"
# tag fabric images to nexusrepo
cd $GOPATH/src/github.com/hyperledger/fabric

IS_RELEASE=`cat Makefile | grep IS_RELEASE | awk '{print $3 }'`
FABRIC_BASE_VERSION=`cat Makefile | grep "BASE_VERSION ="  | awk '{print $3}'`
echo "=======> FABRIC_BASE_VERSION = $FABRIC_BASE_VERSION"
cd $GOPATH/src/github.com/hyperledger/fabric-ca
CA_BASE_VERSION=`cat Makefile | grep "BASE_VERSION ="  | awk '{print $3}'`
echo "=======> CA_BASE_VERSION = $CA_BASE_VERSION"
ARCH=`uname -m`
FABRIC_TAG=$GIT_COMMIT
FABRIC_DOCKER_TAG=${FABRIC_TAG:0:7}
echo "=======> FABRIC_DOCKER_TAG = $FABRIC_DOCKER_TAG"
CA_TAG=$CA_COMMIT
CA_DOCKER_TAG=${CA_TAG:0:7}
echo "=======> CA_DOCKER_TAG = $CA_DOCKER_TAG"
echo
echo "==========> IS_RELEASE = $IS_RELEASE"
if [ "$IS_RELEASE" == "true" ];
then
    export FABRIC_TAG=$ARCH-$FABRIC_BASE_VERSION
    export CA_TAG=$ARCH-$CA_BASE_VERSION
    echo "====> FABRIC_TAG: $FABRIC_TAG"
else
    export FABRIC_TAG=$ARCH-$FABRIC_BASE_VERSION-snapshot-$FABRIC_DOCKER_TAG
    echo "====> FABRIC_TAG: $FABRIC_TAG"
    export CA_TAG=$ARCH-$CA_BASE_VERSION-snapshot-$CA_DOCKER_TAG
    echo "====> CA_TAG: $CA_TAG"
fi

dockerTag() {
  for IMAGES in peer orderer ccenv javaenv tools; do
    echo "==> $IMAGES"
    echo
    docker tag $ORG_NAME-$IMAGES:latest $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG"
    echo
  done
}
dockerCaTag() {
  echo
  docker tag $ORG_NAME-ca:latest $NEXUS_URL/$ORG_NAME-ca:$CA_TAG
  echo "==> $NEXUS_URL/$ORG_NAME-ca:$CA_TAG"
}
# Push docker images to nexus repository

dockerFabricPush() {
  for IMAGES in peer orderer ccenv javaenv tools; do
    echo "==> $IMAGES"
    docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG
    echo
    docker push $NEXUS_URL/$ORG_NAME-$IMAGES
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG"
  done
}

dockerCaPush() {
  docker push $NEXUS_URL/$ORG_NAME-ca:$CA_TAG
  echo
  docker push $NEXUS_URL/$ORG_NAME-ca
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
