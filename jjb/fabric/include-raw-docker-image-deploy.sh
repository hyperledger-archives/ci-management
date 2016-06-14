#!/bin/bash -eu
set -o pipefail

TAG=${GIT_COMMIT:0:7}
PEER_IMAGE="$(docker images -q hyperledger/fabric-peer)"
MEMBER_IMAGE="$(docker images -q hyperledger/fabric-membersrvc)"

echo "COMMIT NUMBER: " $TAG
echo "ARCH: " $ARCH
echo "peer image: " $PEER_IMAGE
echo "membersrvc image: " $MEMBER_IMAGE

docker tag $PEER_IMAGE hyperledgergithub/fabric-peer:$ARCH-$TAG
docker tag -f $PEER_IMAGE hyperledgergithub/fabric-peer:latest
docker tag $MEMBER_IMAGE hyperledgergithub/fabric-membersrvc:$ARCH-$TAG
docker tag -f $MEMBER_IMAGE hyperledgergithub/fabric-membersrvc:latest

echo "--> Logging into Docker Hub"
docker login --email=$DOCKER_HUB_EMAIL --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD

echo "--> Pushing Docker Tags to Docker Hub"
docker push hyperledgergithub/fabric-peer:$ARCH-$TAG
docker push hyperledgergithub/fabric-peer:latest
docker push hyperledgergithub/fabric-membersrvc:$ARCH-$TAG
docker push hyperledgergithub/fabric-membersrvc:latest
