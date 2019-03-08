#!/bin/bash -e

ORG_NAME="hyperledger"
IMAGES_LIST=(explorer explorer-db)
export IMAGES_LIST
TAG=$(git describe --abbrev=0 --tags | cut -d 'v' -f 2)
docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD

# Clone blockchain-explorer git repository
clone_Blockchain_Explorer() {
    rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/blockchain-explorer
    WD="${WORKSPACE}/gopath/src/github.com/hyperledger/blockchain-explorer"
    REPO_NAME=blockchain-explorer
    git clone --single-branch -b $GERRIT_BRANCH git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
    cd $WD
    git checkout $GERRIT_BRANCH
    RELEASE_COMMIT=$(git log -1 --pretty=format:"%h")
    echo "-------> INFO: RELEASE_COMMIT" $RELEASE_COMMIT
    echo "-------> INFO: RELEASE TAG: $TAG"
}


# Build blockchain-explorer images
docker_Build_Images() {
     # build "explorer & explorer-db" images
     ./build_docker_image.sh
}

# list docker images
docker images | grep hyperledger

docker_Explorer_Push() {
    # Clone blockchain-explorer
    clone_Blockchain_Explorer
    # Call to build blockchain-explorer images
    docker_Build_Images
    for IMAGES in ${IMAGES_LIST[*]}; do
      # Tag with latest & ($PUSH_VERSION)
      docker tag $ORG_NAME/$IMAGES $ORG_NAME/$IMAGES:$1
      docker tag $ORG_NAME/$IMAGES $ORG_NAME/$IMAGES
      echo "------> Push blockchain-explorer Images to hyperledger dockerhub Repository"
      docker push $ORG_NAME/$IMAGES:$1
      docker push $ORG_NAME/$IMAGES
    done
}

docker_Explorer_Push $TAG

# list docker images
docker images | grep hyperledger
