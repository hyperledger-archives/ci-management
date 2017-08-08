#!/bin/bash -eu

set -o pipefail

# RUN END-to-END Tests
######################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples

SAMPLES_WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"

git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$REPO_NAME $SAMPLES_WD
cd $WD && make release

cp -r $WD/release/linux-amd64/bin/ $SAMPLES_WD

cd $SAMPLES_WD/first-network
export PATH=$SAMPLES_WD/bin:$PATH

echo
echo "======> DEFAULT CHANNEL <======"

echo y | ./byfn.sh -m down
echo y | ./byfn.sh -m generate
echo y | ./byfn.sh -m up -t 10 && docker ps -a && docker logs -f cli | tee default_channel.log
echo y | ./byfn.sh -m down

echo
echo "======> CUSTOM CHANNEL <======="

echo y | ./byfn.sh -m generate -c fabricrelease
echo y | ./byfn.sh -m up -c fabricrelease -t 10 && docker ps -a && docker logs -f cli | tee custom_channel.log
echo y | ./byfn.sh -m down
