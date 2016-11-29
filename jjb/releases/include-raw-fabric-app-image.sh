#!/bin/bash
set -o pipefail

TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-peer | sed 's/.*:\(.*\)]/\1/')

echo "Images TAG ID is: " $TAG

echo "--> Pushing Docker Tags to Docker Hub"
docker push hyperledger/fabric-peer:$TAG
docker push hyperledger/fabric-javaenv:$TAG
docker push hyperledger/fabric-ccenv:$TAG
docker push hyperledger/fabric-orderer:$TAG

