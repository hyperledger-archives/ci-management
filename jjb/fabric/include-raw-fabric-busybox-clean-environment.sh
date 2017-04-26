#!/bin/bash -exu
set -o pipefail

make clean || true
docker rmi -f "$(docker images | grep dev | awk '{print $3}')" || true
docker rmi -f "$(docker images | grep none | awk '{print $3}')" || true
docker rm -f "$(docker ps -aq)" || true
docker rmi -f "$(docker images | grep "hyperledger/fabric-baseimage:*")" || true
