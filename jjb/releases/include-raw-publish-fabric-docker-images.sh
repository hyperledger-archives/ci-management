#!/bin/bash -e

############################################
# Pull "1.2.0-stable" docker images from nexus3
# Tag it as $ARCH-$RELEASE_VERSION (1.2.0)
# Push tagged images to hyperledger dockerhub
#############################################

ORG_NAME=hyperledger/fabric
export ORG_NAME
NEXUS_URL=nexus3.hyperledger.org:10001
export NEXUS_URL
: ${STABLE_VERSION:=1.2.0-stable}
IMAGES_LIST=(peer orderer ccenv tools)
export IMAGES_LIST
THIRDPARTY_IMAGES_LIST=(kafka couchdb zookeeper)
export THIRDPARTY_IMAGES_LIST

ARCH=$(go env GOARCH)
echo "ARCH" $ARCH
if [ "$ARCH" = "amd64" ]; then
	ARCH=amd64
else
    ARCH=$(uname -m)
fi

printHelp() {
  echo "Usage: RELEASE_VERSION=1.2.0 ./scripts/pull_Build_Artifacts.sh --pull_Images"
  echo
  echo "pull_All - pull fabric thirdparty, fabric docker images, binaries on current arch"
  echo "pull_Platform_All - pull fabric images amd64, s390x"
  echo "cleanup - delete unused docker images"
  echo "pull_Images - pull fabric docker images on current arch"
  echo "pull_Binary - pull fabric binaries on current arch"
  echo "pull_Thirdparty - pull fabric thirdparty docker images"
  echo "push - push images to hyperledger dockerhub"
  echo
  echo "e.g. RELEASE_VERSION=1.2.0 ./scripts/pull-build_artifacts.sh --push"
  echo "e.g. RELEASE_VERSION=1.2.0 ./scripts/pull-build_artifacts.sh --pull_Images"
}

# pull fabric binaries
pull_Binary() {
    MARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
    export MARCH
    echo "------> MARCH:" $MARCH
    echo "-------> pull stable binaries for all platforms (x and z)"
    MVN_METADATA=$(echo "https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-$STABLE_VERSION/maven-metadata.xml")
    curl -L "$MVN_METADATA" > maven-metadata.xml
    RELEASE_TAG=$(cat maven-metadata.xml | grep release)
    COMMIT=$(echo $RELEASE_TAG | awk -F - '{ print $4 }' | cut -d "<" -f1)
    echo "--------> COMMIT:" $COMMIT
    curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-$STABLE_VERSION/$MARCH.$STABLE_VERSION-$COMMIT/hyperledger-fabric-$STABLE_VERSION-$MARCH.$STABLE_VERSION-$COMMIT.tar.gz | tar xz
}

# pull fabric docker images from amd64 and s390x platforms
pull_Platform_All() {

    # pull stable images from nexus and tag to hyperledger
    echo "-------> pull docker images for all platforms (x, z)"
# Disable this fix FAB-10904 (release-1.2 supports only x)
#    for arch in amd64 s390x; do
# echo "---------> arch:" $arch
        for IMAGES in ${IMAGES_LIST[*]}; do
            docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$arch-$STABLE_VERSION
            docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$arch-$STABLE_VERSION $ORG_NAME-$IMAGES:$arch-$1
            docker rmi -f $NEXUS_URL/$ORG_NAME-$IMAGES:$arch-$STABLE_VERSION
        done
}

push() {
# pull fabric images
    pull_Platform_All $1
# push docker images
    echo "------> push docker images"
    docker login -u $DOCKER_HUB_USERNAME -p $DOCKER_HUB_PASSWORD
#    for MARCH in amd64 s390x; do
        for IMAGES in ${IMAGES_LIST[*]}; do
            docker push $ORG_NAME-$IMAGES:$arch-$1
        done
}

# pull thirdparty docker images from nexus
pull_Thirdparty() {
    echo "------> pull thirdparty docker images from nexus"
    BASE_VERSION=$(curl --silent  https://raw.githubusercontent.com/hyperledger/fabric/master/Makefile 2>&1 | tee Makefile | grep "BASEIMAGE_RELEASE=" | cut -d "=" -f2)
    for IMAGES in ${THIRDPARTY_IMAGES_LIST[*]}; do
          docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$BASE_VERSION
          docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$BASE_VERSION $ORG_NAME-$IMAGES
          docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$BASE_VERSION $ORG_NAME-$IMAGES:$ARCH-$BASE_VERSION
          docker rmi -f $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$BASE_VERSION
    done
}

# Push Release
arch=amd64
push $PUSH_VERSION
