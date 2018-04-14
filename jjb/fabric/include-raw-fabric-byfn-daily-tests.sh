#!/bin/bash

# RUN BYFN END-to-END Tests
######################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples

# Docker Container list
CONTAINER_LIST=(peer0.org1 peer1.org1 peer0.org2 peer1.org2 peer0.org3 peer1.org3 orderer)
COUCHDB_CONTAINER_LIST=(couchdb0 couchdb1 couchdb2 couchdb3 couchdb4 couchdb5)

git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
cd $WD || exit
git checkout $GERRIT_BRANCH
echo "-------> GERRIT_BRANCH: $GERRIT_BRANCH"
FABRIC_SAMPLES_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC_SAMPLES_COMMIT ========> $FABRIC_SAMPLES_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
# copy /bin directory to fabric-samples
cp -r ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/release/linux-amd64/bin/ .

# Create Logs directory
mkdir -p $WORKSPACE/Docker_Container_Logs

cd first-network || exit
#Set INFO to DEBUG
sed -it 's/INFO/DEBUG/' base/peer-base.yaml
export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

artifacts() {

    echo "---> Archiving generated logs"
    mkdir -p "$WORKSPACE/archives"
    mv "$WORKSPACE/Docker_Container_Logs" $WORKSPACE/archives/
}

# Capture docker logs of each container
logs() {

for CONTAINER in ${CONTAINER_LIST[*]}; do
    docker logs $CONTAINER.example.com >& $WORKSPACE/Docker_Container_Logs/$CONTAINER-$1.log
    echo
done

if [ ! -z $2 ]; then

for CONTAINER in ${COUCHDB_CONTAINER_LIST[*]}; do
    docker logs $CONTAINER >& $WORKSPACE/Docker_Container_Logs/$CONTAINER-$1.log
    echo
done
fi
}

copy_logs() {

   # Call logs function
    logs $2 $3

if [ $1 != 0 ]; then

    artifacts
    exit 1
fi
}

echo "------> Deleting Containers...."
# shellcheck disable=SC2046
docker rm -f $(docker ps -aq)
echo "------> List Docker Containers"
docker ps -aq

# Execute below tests
echo "############## BYFN,EYFN DEFAULT TEST####################"
echo "#########################################################"

echo y | ./byfn.sh -m down
echo y | ./byfn.sh -m generate
copy_logs $? default-channel
echo y | ./byfn.sh -m up -t 60
copy_logs $? default-channel
echo y | ./eyfn.sh -m up
copy_logs $? default-channel
echo y | ./eyfn.sh -m down
echo
echo "############## BYFN,EYFN CUSTOM CHANNEL TEST#############"
echo "#########################################################"

echo y | ./byfn.sh -m generate -c custom-channel
copy_logs $? custom-channel
echo y | ./byfn.sh -m up -c custom-channel -t 60
copy_logs $? custom-channel
echo y | ./eyfn.sh -m up -c custom-channel -t 60
copy_logs $? custom-channel
echo y | ./eyfn.sh -m down
echo
echo "############### BYFN,EYFN COUCHDB TEST #############"
echo "####################################################"

echo y | ./byfn.sh -m generate -c couchdbtest
copy_logs $? custom_channel_couchdb couchdb
echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 60
copy_logs $? custom_channel_couchdb couchdb
echo y | ./eyfn.sh -m up -c couchdbtest -s couchdb -t 60
copy_logs $? custom_channel_couchdb couchdb
echo y | ./eyfn.sh -m down
echo
echo "############### BYFN,EYFN NODE Chaincode TEST ################"
echo "####################################################"

echo y | ./byfn.sh -m up -l node -t 60
copy_logs $? default-channel-node
echo y | ./eyfn.sh -m up -l node -t 60
copy_logs $? default-channel-node
echo y | ./eyfn.sh -m down

echo "############### fabric-ca samples TEST ################"
echo "####################################################"

cd $WD/fabric-ca && ./start.sh && ./stop.sh

artifacts
