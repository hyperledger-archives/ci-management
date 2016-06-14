#!/bin/bash -eu
set -o pipefail

TAG=${GIT_COMMIT:0:7}

echo "COMMIT NUMBER: " $TAG
echo "ARCH: " $ARCH

PEER_IMAGE="$(docker images -q hyperledger/fabric-peer)"
MEMBER_IMAGE="$(docker images -q hyperledger/fabric-membersrvc)"
PEER_TAG=$PEER_IMAGE:$ARCH-$TAG
MEMBER_TAG=$MEMBER_IMAGE:$ARCH-$TAG

echo "peer tag: " $PEER_TAG
echo "membersrvc tag: " $MEMBER_TAG

docker tag $PEER_TAG hyperledgergithub/fabric-peer:$TAG
docker tag -f $PEER_TAG hyperledgergithub/fabric-peer:latest
docker tag $MEMBER_TAG hyperledgergithub/fabric-membersrvc:$TAG
docker tag -f $MEMBER_TAG hyperledgergithub/fabric-membersrvc:latest

echo "--> Logging into Docker Hub"
docker login --email=$DOCKER_HUB_EMAIL --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD

echo "--> Pushing Docker Tags to Docker Hub"
docker push hyperledgergithub/fabric-peer:$TAG
docker push hyperledgergithub/fabric-peer:latest
docker push hyperledgergithub/fabric-membersrvc:$TAG
docker push hyperledgergithub/fabric-membersrvc:latest
