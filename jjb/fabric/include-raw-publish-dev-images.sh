#!/bin/bash -eu
set -o pipefail

NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"

# Clone & Build fabric docker images
#####################################

cd gopath/src/github.com/hyperledger/fabric
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC_COMMIT ===========> $FABRIC_COMMIT" >> commit.log
mv commit.log ${WORKSPACE}/gopath/src/github.com/hyperledger/
make docker && docker images | grep hyperledger

# Clone & Build fabric-ca docker images
#######################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$CA_REPO_NAME $WD
cd $WD
CA_COMMIT=$(git log -1 --pretty=format:"%h")
make docker && docker images | grep hyperledger
echo "CA COMMIT ========> $CA_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log

############################################
#publish docker images to Nexus3 docker repo
############################################

cd $GOPATH/src/github.com/hyperledger/fabric

IS_RELEASE=`cat Makefile | grep IS_RELEASE | awk '{print $3 }'`
FABRIC_BASE_VERSION=`cat Makefile | grep "BASE_VERSION ="  | awk '{print $3}'`
echo "=======> FABRIC_BASE_VERSION = $FABRIC_BASE_VERSION"

BASE_IMAGE_RELEASE=`cat Makefile | grep "BASEIMAGE_RELEASE=" | cut -d '=' -f 2`
echo "=======> BASE_IMAGE_RELEASE = $BASE_IMAGE_RELEASE"

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

dockerFabricTag() {
  for IMAGES in peer orderer ccenv tools; do
    echo "==> $IMAGES"
    echo
    docker tag $ORG_NAME-$IMAGES:latest $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG
    docker tag $ORG_NAME-$IMAGES:latest $NEXUS_URL/$ORG_NAME-$IMAGES
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG"
    echo
  done
}
dockerFabricPush() {
  for IMAGES in peer orderer ccenv tools; do
    echo "==> $IMAGES"
    docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG
    echo
    docker push $NEXUS_URL/$ORG_NAME-$IMAGES
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$FABRIC_TAG"
  done
}

dockerCaTag() {
  echo
  docker tag $ORG_NAME-ca:latest $NEXUS_URL/$ORG_NAME-ca:$CA_TAG
  docker tag $ORG_NAME-ca:latest $NEXUS_URL/$ORG_NAME-ca
  echo "==> $NEXUS_URL/$ORG_NAME-ca:$CA_TAG"
}
dockerCaPush() {
  docker push $NEXUS_URL/$ORG_NAME-ca:$CA_TAG
  echo
  docker push $NEXUS_URL/$ORG_NAME-ca
  echo "==> $NEXUS_URL/$ORG_NAME-ca:$CA_TAG"
}

dockerThirdPartyDockerTag() {
  for IMAGES in kafka zookeeper couchdb; do
     docker pull $ORG_NAME-$IMAGES:$ARCH-$BASE_IMAGE_RELEASE
     docker tag $ORG_NAME-$IMAGES:$ARCH-$BASE_IMAGE_RELEASE $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$BASE_IMAGE_RELEASE
     docker tag $ORG_NAME-$IMAGES:$ARCH-$BASE_IMAGE_RELEASE $NEXUS_URL/$ORG_NAME-$IMAGES
     echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$BASE_IMAGE_RELEASE"
  done
}
dockerThirdPartyDockerPush() {
  for IMAGES in kafka zookeeper couchdb; do
    docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$BASE_IMAGE_RELEASE
    echo
    docker push $NEXUS_URL/$ORG_NAME-$IMAGES
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES"
  done
}

# Tag & Push Fabric Docker Images to Nexus Repository
dockerFabricTag
dockerFabricPush

# Tag & Push Fabric-ca Docker Image to Nexus Repository
dockerCaTag
dockerCaPush

# Tag & Push docker thirdparty docker images to nexus repo
dockerThirdPartyDockerTag
dockerThirdPartyDockerPush

# Listout all docker images Before and After Push to NEXUS
docker images | grep "nexus*"
