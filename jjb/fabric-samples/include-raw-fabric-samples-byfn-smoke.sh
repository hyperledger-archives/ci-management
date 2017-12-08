#!/bin/bash -eu

set -o pipefail

# RUN END-to-END Tests
######################

cd gopath/src/github.com/hyperledger/fabric-samples
# copy /bin directory to fabric-samples
cp -r ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/release/linux-amd64/bin/ .

cd first-network
export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH
# Execute below tests
echo
echo "======> DEFAULT CHANNEL <======"

echo y | ./byfn.sh -m down
echo y | ./byfn.sh -m generate
echo y | ./byfn.sh -m up -t 10
echo y | ./byfn.sh -m down

echo
echo "======> CUSTOM CHANNEL <======="

echo y | ./byfn.sh -m generate -c fabricrelease
echo y | ./byfn.sh -m up -c fabricrelease -t 10
echo y | ./byfn.sh -m down


echo
echo "======> CouchDB tests <======="

echo y | ./byfn.sh -m generate -c couchdbtest
echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 10
echo y | ./byfn.sh -m down
