#!/bin/bash
set -o pipefail

FABRIC_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-peer | sed 's/.*:\(.*\)]/\1/')
echo "FABRIC Images TAG ID is: " $FABRIC_TAG
echo
ORG_NAME="hyperledger/fabric"

docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
# Push docker images to nexus repository

#TODO: this is a temporary change to push 1.0.6 thirdparty images
#This process has to steamline or add other fabric images to the below list

docker_Fabric_Thirdparty_Push() {

  # shellcheck disable=SC2043
  for IMAGES in kafka couchdb zookeeper; do
    echo "==> $IMAGES"
    docker push $ORG_NAME-$IMAGES:$FABRIC_TAG
    echo
    echo "==> $ORG_NAME-$IMAGES:$FABRIC_TAG"
    echo
  done
}

docker_Fabric_Push() {

  # shellcheck disable=SC2043
  for IMAGES in peer orderer ccenv javaenv tools; do
    echo "==> $IMAGES"
    docker push $ORG_NAME-$IMAGES:$FABRIC_TAG
    echo
    echo "==> $ORG_NAME-$IMAGES:$FABRIC_TAG"
    echo
  done
}
echo "-----> GERRIT_REFSPEC is: $GERRIT_REFSPEC"
echo $GERRIT_REFSPEC | grep 'v1.0.*'
if [ $? != '0' ]; then

     # Push Fabric Docker Images
     echo "-----> Release tag: $GERRIT_REFSPEC"
     echo "-----> Pushing fabric and thirdparty docker imges"
     docker_Fabric_Push
else
     # Push Fabric & Thirdparty Docker Images
     echo "-----> Release tag: $GERRIT_REFSPEC"
     echo "-----> Pushing fabric and thirdparty docker imges"
     docker_Fabric_Thirdparty_Push
fi
# Listout all docker images Before and After Push to NEXUS
docker images | grep "hyperledger*"
