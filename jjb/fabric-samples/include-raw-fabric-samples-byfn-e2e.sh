#!/bin/bash -eu
set -o pipefail

# RUN END-to-END Test
#####################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples

git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$REPO_NAME $WD
cd $WD
#cp -r ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/release/linux-amd64/bin .

curl -L https://raw.githubusercontent.com/hyperledger/fabric/master/scripts/bootstrap-1.0.0.sh -o bootstrap-1.0.0.sh
chmod +x bootstrap-1.0.0.sh
./bootstrap-1.0.0.sh

cd $WD/first-network
export PATH=$WD/bin:$PATH
#
echo "=======> DEFAULUT CHANNEL"
echo y | ./byfn.sh -m generate
echo y | ./byfn.sh -m up -t 10
echo y | ./byfn.sh -m down

#
echo "=======> CUSTOM CHANNEL"

echo y | ./byfn.sh -m generate -c fabricrelease
echo y | ./byfn.sh -m up -c fabricrelease -t 10
echo y | ./byfn.sh -m down
