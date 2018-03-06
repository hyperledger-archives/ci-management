#!/bin/bash

# RUN BYFN END-to-END Tests
######################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples

# Docker Container list
CONTAINER_LIST=(peer0.org1 peer1.org2 peer0.org2 peer1.org1 orderer peer0.org3 peer1.org3)

git clone https://gerrit.hyperledger.org/r/$REPO_NAME $WD
cd $WD || exit
git checkout $GERRIT_BRANCH
echo "-------> GERRIT_BRANCH: $GERRIT_BRANCH"
FABRIC_SAMPLES_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC_SAMPLES_COMMIT ========> $FABRIC_SAMPLES_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
# copy /bin directory to fabric-samples
cp -r ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/release/linux-amd64/bin/ .

cd first-network || exit
#Set INFO to DEBUG
sed -it 's/INFO/DEBUG/' base/peer-base.yaml
export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

#Docker logs
logs() {

for CONTAINER in ${CONTAINER_LIST[*]}; do
    docker logs $CONTAINER.example.com >& $WORKSPACE/$CONTAINER-$1.log #2>&1 &
    echo
done
}

copy_logs() {

if [ $? == 0 ]; then
    # Call logs function
    logs $1
else
    # Calls logs function
    logs $1
    exit 1
fi
}

# Execute below tests
echo "############## BYFN,EYFN DEFAULT TEST####################"
echo "#########################################################"

echo y | ./byfn.sh -m down
echo y | ./byfn.sh -m generate
echo y | ./byfn.sh -m up -t 60
echo y | ./eyfn.sh -m up
copy_logs default_channel
echo y | ./eyfn.sh -m down
echo
echo "############## BYFN,EYFN CUSTOM CHANNEL TEST#############"
echo "#########################################################"

echo y | ./byfn.sh -m generate -c custom_channel
echo y | ./byfn.sh -m up -c custom-channel -t 60
echo y | ./eyfn.sh -m up -c custom-channel -t 60
copy_logs custom-channel
echo y | ./eyfn.sh -m down
echo
echo "############### BYFN,EYFN COUCHDB TEST #############"
echo "####################################################"

echo y | ./byfn.sh -m generate -c couchdbtest
echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 60
echo y | ./eyfn.sh -m up -c couchdbtest -s couchdb -t 60
copy_logs custom_channel_couchdb
echo y | ./eyfn.sh -m down
echo
echo "############### BYFN,EYFN NODE Chaincode TEST ################"
echo "####################################################"

echo y | ./byfn.sh -m up -l node -t 60
echo y | ./eyfn.sh -m up -l node -t 60
copy_logs default_channel_node
echo y | ./eyfn.sh -m down
