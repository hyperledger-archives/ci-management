#!/bin/bash -eu
set -o pipefail

# RUN BYFN END-to-END Tests
######################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples

git clone https://gerrit.hyperledger.org/r/$REPO_NAME $WD
cd $WD || exit
git checkout $GERRIT_BRANCH
echo "-------> GERRIT_BRANCH: $GERRIT_BRANCH"
FABRIC_SAMPLES_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC_SAMPLES_COMMIT ========> $FABRIC_SAMPLES_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
# copy /bin directory to fabric-samples
cp -r ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/release/linux-amd64/bin/ .

cd first-network
export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

# Execute below tests
echo "############## BYFN,EYFN DEFAULT TEST####################"
echo "#########################################################"

echo y | ./byfn.sh -m down
echo y | ./byfn.sh -m generate
echo y | ./byfn.sh -m up -t 60
echo y | ./eyfn.sh -m up
echo y | ./eyfn.sh -m down
echo
echo "############## BYFN,EYFN CUSTOM CHANNEL TEST#############"
echo "#########################################################"

echo y | ./byfn.sh -m generate -c fabricrelease
echo y | ./byfn.sh -m up -c fabricrelease -t 60
echo y | ./eyfn.sh -m up -c fabricrelease -t 60
echo y | ./eyfn.sh -m down
echo
echo "############### BYFN,EYFN COUCHDB TEST #############"
echo "####################################################"

echo y | ./byfn.sh -m generate -c couchdbtest
echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 60
echo y | ./eyfn.sh -m up -c couchdbtest -s couchdb -t 60
echo y | ./eyfn.sh -m down
echo
echo "############### BYFN,EYFN NODE TEST ################"
echo "####################################################"

echo y | ./byfn.sh -m up -l node -t 60
echo y | ./eyfn.sh -m up -l node -t 60
echo y | ./eyfn.sh -m down
