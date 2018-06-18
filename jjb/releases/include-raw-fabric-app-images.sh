#!/bin/bash
set -o pipefail

FABRIC_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-peer | sed 's/.*:\(.*\)]/\1/')
echo "FABRIC Images TAG ID is: " $FABRIC_TAG
echo
ORG_NAME="hyperledger/fabric"

docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
# Push docker images to nexus repository

#TODO: this is a temporary change to push 1.0.x thirdparty images

docker_Fabric_Thirdparty_Push() {

  # shellcheck disable=SC2043
  for IMAGES in kafka zookeeper couchdb javaenv; do
    echo "==> $IMAGES"
    docker push $ORG_NAME-$IMAGES:$FABRIC_TAG
    echo
    echo "==> $ORG_NAME-$IMAGES:$FABRIC_TAG"
    echo
  done
}

docker_Fabric_Push() {

  # shellcheck disable=SC2043
  for IMAGES in peer orderer ccenv tools; do
    echo "==> $IMAGES"
    docker push $ORG_NAME-$IMAGES:$FABRIC_TAG
    echo
    echo "==> $ORG_NAME-$IMAGES:$FABRIC_TAG"
    echo
  done
}

BRANCH=$(echo $GIT_BRANCH | grep 'v1.0.*')
REFSPEC=$(echo $GERRIT_REFSPEC | grep 'v1.0.*')

if [ -z "$BRANCH" ] && [ -z "$REFSPEC" ]; then
     # Push Fabric Docker Images from master branch
     echo "-----> Release tag: $GERRIT_REFSPEC"
     echo "-----> GIT_BRANCH: $GIT_BRANCH"
     echo "-----> Pushing fabric docker images from master branch"
     docker_Fabric_Push
else
     # Push Fabric & Thirdparty Docker Images from release branch
     echo "-----> Release tag: $GERRIT_REFSPEC"
     echo "-----> GIT_BRANCH: $GIT_BRANCH"
     echo "-----> Pushing fabric and thirdparty docker images from release branch"
     docker_Fabric_Push
     docker_Fabric_Thirdparty_Push
fi
# Listout all the docker images Before and After Push
docker images | grep "hyperledger*"
