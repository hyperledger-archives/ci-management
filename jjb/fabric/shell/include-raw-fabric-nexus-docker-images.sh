#!/bin/bash
set -o pipefail

NEXUS_URL=nexus3.hyperledger.org:10002
ORG_NAME="hyperledger/fabric"

docker_Fabric_Thirdparty_Push() {

  # shellcheck disable=SC2043
  for IMAGES in kafka zookeeper couchdb; do
    echo "==> $IMAGES"
    docker tag $ORG_NAME-$IMAGES:$1 $NEXUS_URL/$ORG_NAME-$IMAGES:$1
    docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$1
    echo
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$1"
    echo
  done
}

docker_Fabric_Push() {

  # shellcheck disable=SC2043
  for IMAGES in peer orderer ccenv tools; do
    echo "==> $IMAGES"
    docker tag $ORG_NAME-$IMAGES:$1 $NEXUS_URL/$ORG_NAME-$IMAGES:amd64-$2
    docker push $NEXUS_URL/$ORG_NAME-$IMAGES:amd64-$2
    echo
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:amd64-$2"
    echo
  done
}

BRANCH=$(echo $GIT_BRANCH | grep 'v1.0.*')
REFSPEC=$(echo $GERRIT_REFSPEC | grep 'v1.0.*')

if [ -z "$BRANCH" ] && [ -z "$REFSPEC" ]; then
     # Push Fabric Docker Images from master branch
     echo "-----> Release tag: $GERRIT_REFSPEC"
     echo "-----> GIT_BRANCH: $GIT_BRANCH"
     echo "-----> Pushing fabric docker images from $BRANCH branch"

     FABRIC_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-peer | sed 's/.*:\(.*\)]/\1/')
     echo "FABRIC Images TAG ID is: " $FABRIC_TAG

     REL_VER=$(echo $FABRIC_TAG | cut -d "-" -f2)
     echo "------> REL_VER = $REL_VER"
     docker_Fabric_Push $FABRIC_TAG $REL_VER
else
     # Push Fabric & Thirdparty Docker Images from $BRANCH branch
     echo "-----> Release tag: $GERRIT_REFSPEC"
     echo "-----> GIT_BRANCH: $GIT_BRANCH"

     echo "-----> Pushing fabric and thirdparty docker images from $BRANCH branch"
     FABRIC_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-peer | sed 's/.*:\(.*\)]/\1/')
     echo "FABRIC Images TAG ID is: " $FABRIC_TAG

     REL_VER=$(echo $FABRIC_TAG | cut -d "-" -f2)
     echo "------> REL_VER = $REL_VER"
     docker_Fabric_Push $FABRIC_TAG $REL_VER

     THIRDPARTY_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-kafka | sed 's/.*:\(.*\)]/\1/')
     echo "FABRIC Images TAG ID is: " $THIRDPARTY_TAG

     REL_VER=$(echo $FABRIC_TAG | cut -d "-" -f2)
     echo "------> REL_VER = $REL_VER"
     docker_Fabric_Thirdparty_Push $THIRDPARTY_TAG $REL_VER

fi
# Listout all the docker images Before and After Push
docker images
