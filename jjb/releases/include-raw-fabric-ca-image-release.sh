#!/bin/bash
set -o pipefail

docker login --email=$DOCKER_HUB_EMAIL --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD

TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-ca | sed 's/.*:\(.*\)]/\1/')

echo "Image TAG ID is: " $TAG

echo "--> Pushing Docker Tags to Docker Hub"
docker push hyperledger/fabric-ca:$TAG

