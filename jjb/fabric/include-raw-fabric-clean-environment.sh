#!/bin/bash -eu
cd gopath/src/github.com/hyperledger/fabric
# Configure ip/port
ip="$(ifconfig docker0 | grep 'inet[^6]' | awk '{print $2}' | cut -d ':' -f 2)"
port=2375
# script
#sed -i -e 's/172.17.0.1:2375\b/'"$ip:$port"'/g' bddtests/compose-defaults.yml
make dist-clean || true
docker rmi -f $(docker images | grep dev | awk '{print $3}') || true
docker rmi -f $(docker images | grep none | awk '{print $3}') || true
docker rm -f $(docker ps -aq) || true
