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
BYFN_COMMIT=$(git log -1 --pretty=format:"%h")
echo "BYFN_COMMIT ===========> $BYFN_COMMIT"
echo "BYFN COMMIT ========> $BYFN_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
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
