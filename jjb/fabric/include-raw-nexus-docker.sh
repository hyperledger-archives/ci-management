#!/bin/bash -exu

set -o pipefail

PEER_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-peer | sed 's/.*:\(.*\)]/\1/')

NEXUS_URL=nexus3.hyperledger.org:10003

docker tag hyperledger/fabric-peer:latest $NEXUS_URL/hyperledger/fabric-peer:$PEER_TAG
docker tag hyperledger/fabric-peer:latest $NEXUS_URL/hyperledger/fabric-peer:latest

docker images | grep hyperledger*

docker push $NEXUS_URL/hyperledger/fabric-peer:latest
docker push $NEXUS_URL/hyperledger/fabric-peer:$PEER_TAG
