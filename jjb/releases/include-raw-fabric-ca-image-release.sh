#!/bin/bash
set -o pipefail

TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-ca | sed 's/.*:\(.*\)]/\1/')

echo "Image TAG ID is: " $TAG

echo "--> Pushing Docker Tags to Docker Hub"
docker push hyperledger/fabric-ca:$TAG

