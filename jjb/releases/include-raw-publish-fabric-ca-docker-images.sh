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
STABLE_VERSION=1.2.0-stable
export STABLE_VERSION
RELEASE_VERSION=${RELEASE_VERSION:-1.2.0}
export RELEASE_VERSION
IMAGES_LIST=(ca ca-tools ca-orderer ca-peer)
export IMAGES_LIST

ARCH=$(go env GOARCH)
if [ "$ARCH" = "amd64" ]; then
	ARCH=amd64
else
    ARCH=$(uname -m)
fi

printHelp() {
  echo "Usage: RELEASE_VERSION=1.2.0 ./scripts/pull_Build_Artifacts.sh --pull_Images"
  echo
  echo "pull_All - pull fabric-ca docker images, binaries on current arch"
  echo "pull_Platform_All - pull fabric images amd64, s390x"
  echo "cleanup - delete unused docker images"
  echo "pull_Images - pull fabric-ca docker images on current arch"
  echo "pull_Binary - pull fabric-ca binaries on current arch"
  echo "push - push images to hyperledger dockerhub"
  echo
  echo "e.g. RELEASE_VERSION=1.2.0 ./scripts/pull-build_artifacts.sh --push"
  echo "e.g. RELEASE_VERSION=1.2.0 ./scripts/pull-build_artifacts.sh --pull_Images"
}

cleanup() {
    # Cleanup docker images
    make clean || true
    docker images -q | xargs docker rmi -f || true

}

# pull fabric-ca docker images and binaries
pull_All() {

    echo "-------> pull binaries"
    pull_Binary
    echo "-------> pull fabric-ca docker images"
    pull_Images
}

# pull fabric-ca docker images
pull_Images() {
        for IMAGES in ${IMAGES_LIST[*]}; do
            docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$STABLE_VERSION
            docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$STABLE_VERSION $ORG_NAME-$IMAGES:$ARCH-$RELEASE_VERSION
            docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$STABLE_VERSION $ORG_NAME-$IMAGES:latest
            docker rmi -f $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-$STABLE_VERSION
        done
}

# pull fabric-ca binaries
pull_Binary() {
    MARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
    export MARCH
    echo "------> MARCH:" $MARCH
    echo "-------> pull stable binaries for all platforms"
    MVN_METADATA=$(echo "https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric-ca/hyperledger-fabric-ca-stable/maven-metadata.xml")
    curl -L "$MVN_METADATA" > maven-metadata.xml
    RELEASE_TAG=$(cat maven-metadata.xml | grep release)
    COMMIT=$(echo $RELEASE_TAG | awk -F - '{ print $4 }' | cut -d "<" -f1)
    echo "--------> COMMIT:" $COMMIT
    curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric-ca/hyperledger-fabric-ca-stable/$MARCH.$STABLE_VERSION-$COMMIT/hyperledger-fabric-ca-stable-$MARCH.$STABLE_VERSION-$COMMIT.tar.gz | tar xz 
}

# pull fabric-ca docker images from amd64 and s390x platforms
pull_Platform_All() {

    # pull stable images from nexus and tag to hyperledger
    echo "-------> pull docker images for all platforms (x, z)"
    for arch in amd64 s390x; do
        for IMAGES in ${IMAGES_LIST[*]}; do
            docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$arch-$STABLE_VERSION
            docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$arch-$STABLE_VERSION $ORG_NAME-$IMAGES:$arch-$1
            docker rmi -f $NEXUS_URL/$ORG_NAME-$IMAGES:$arch-$STABLE_VERSION
        done
    done
}

push() {

# pull fabric-ca images
    pull_Platform_All $1
    echo "------> List all docker images"
    docker images | grep "hyperledger"
# push docker images to hyperledger
    echo "------> push docker images"
    docker login -u $DOCKER_HUB_USERNAME -p $DOCKER_HUB_PASSWORD
    for MARCH in amd64 s390x; do
        for IMAGES in ${IMAGES_LIST[*]}; do
            docker push $ORG_NAME-$IMAGES:$MARCH-$1
        done
    done
}

# Push Release Version to Dockerhub
push $PUSH_VERSION
