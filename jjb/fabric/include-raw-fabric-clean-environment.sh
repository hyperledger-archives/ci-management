#!/bin/bash -eu

cd gopath/src/github.com/hyperledger/fabric

docker rm -f $(docker ps -aq) || true
make dist-clean || true
docker rmi -f $(docker images | grep -v 'hyperledger/fabric-base*' | awk {'print $3'}) || true

