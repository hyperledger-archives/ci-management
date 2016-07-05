#!/bin/bash -eu
cd gopath/src/github.com/hyperledger/fabric
make dist-clean || true
docker rmi -f $(docker images | grep dev | awk '{print $3}') || true
docker rmi -f $(docker images | grep none | awk '{print $3}') || true
docker rm -f $(docker ps -aq) || true
