#!/bin/bash -eu

cd gopath/src/github.com/hyperledger/fabric
docker images
docker ps -a
docker stop hyperledger/fabric-{baseimage,src,ccenv,peer,membersrvc} || true
make dist-clean || true
docker rmi -f $(docker images | grep dev | awk '{print $3}') || true
