#!/bin/bash -eu
set -o pipefail

docker images | grep hyperledger/fabric

TAG="$(docker images hyperledger/fabric-peer | awk 'NR!=1 &&  $2!="latest" {print $2}')"
PEER_IMAGE="$(docker images hyperledger/fabric-peer | awk 'NR!=1 &&  $2!="latest" {print $3}')"
MEMBERSERVC_IMAGE="$(docker images hyperledger/fabric-membersrvc | awk 'NR!=1 &&  $2!="latest" {print $3}')"

echo "PEER TAG: " $TAG
echo "MEMBERSRVC TAG: " $TAG
echo "peer image: " $PEER_IMAGE
echo "membersrvc image: " $MEMBERSERVC_IMAGE

docker tag $PEER_IMAGE hyperledger/fabric-peer-ppc64le:latest
docker tag $MEMBERSERVC_IMAGE hyperledger/fabric-membersrvc-ppc64le:latest

docker tag $PEER_IMAGE hyperledger/fabric-peer-ppc64le:$TAG
docker tag $MEMBERSERVC_IMAGE hyperledger/fabric-membersrvc-ppc64le:$TAG

echo "--> Logging into Docker Hub"
docker login --email=$DOCKER_HUB_EMAIL --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD

echo "--> Pushing Docker Tags to Docker Hub"
docker push hyperledger/fabric-peer-ppc64le:$TAG
docker push hyperledger/fabric-peer-ppc64le:latest
docker push hyperledger/fabric-membersrvc-ppc64le:$TAG
docker push hyperledger/fabric-membersrvc-ppc64le
