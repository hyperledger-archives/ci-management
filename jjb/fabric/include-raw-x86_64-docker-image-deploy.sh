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

echo "--> Logging into Docker Hub"
docker login --email=$DOCKER_HUB_EMAIL --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD

echo "--> Pushing Docker Tags to Docker Hub"
docker push hyperledger/fabric-peer:$TAG
docker push hyperledger/fabric-peer:latest
docker push hyperledger/fabric-membersrvc:$TAG
docker push hyperledger/fabric-membersrvc:latest
