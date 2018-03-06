#!/bin/bash

# docker container list
CONTAINER_LIST=(peer0.org1 peer1.org2 peer0.org2 peer1.org1 orderer peer0.org3 peer1.org3)

cd gopath/src/github.com/hyperledger/fabric-samples || exit
# copy /bin directory to fabric-samples
cp -r ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/release/linux-amd64/bin/ .

cd first-network || exit

#Set INFO to DEBUG
sed -it 's/INFO/DEBUG/' base/peer-base.yaml

export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

# Capture docker logs of each container
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
echo "------> BRANCH: " $GERRIT_BRANCH
if [ $GERRIT_BRANCH == "master" ]; then

	echo "############## BYFN,EYFN DEFAULT CHANNEL TEST####################"
	echo "#################################################################"

	echo y | ./byfn.sh -m down
	echo y | ./byfn.sh -m up -t 60
	echo y | ./eyfn.sh -m up -t 60
        copy_logs default_channel
        echo y | ./eyfn.sh -m down
	echo
	echo "############## BYFN,EYFN CUSTOM CHANNEL TEST#############"
	echo "#########################################################"

	echo y | ./byfn.sh -m up -c custom_channel -t 60
	echo y | ./eyfn.sh -m up -c custom_channel -t 60
        copy_logs custom_channel
	echo y | ./eyfn.sh -m down
	echo
	echo "############### BYFN,EYFN CUSTOME CHANNEL WITH COUCHDB TEST #############"
	echo "#########################################################################"

	echo y | ./byfn.sh -m up -c custom_channel_couch -s couchdb -t 60
	echo y | ./eyfn.sh -m up -c custom_channel_couch -s couchdb -t 60
        copy_logs custom_channel_couch
	echo y | ./eyfn.sh -m down
	echo
	echo "############### BYFN,EYFN WITH NODE Chaincode. TEST ################"
	echo "###############################################################"

	echo y | ./byfn.sh -m up -l node -t 60
	echo y | ./eyfn.sh -m up -l node -t 60
        copy_logs default_channel_node
	echo y | ./eyfn.sh -m down

else
	echo "############## BYFN,EYFN DEFAULT CHANNEL TEST####################"
	echo "#################################################################"
	echo y | ./byfn.sh -m down
        echo y | ./byfn.sh -m up -t 60
        copy_logs default_channel
	echo y | ./byfn.sh -m down
        echo

        echo "############## BYFN,EYFN CUSTOM CHANNEL TEST#############"
        echo "#########################################################"
        echo y | ./byfn.sh -m up -c custom_channel -t 60
        copy_logs custom_channel

	echo "############### BYFN,EYFN CUSTOME CHANNEL WITH COUCHDB TEST #############"
        echo "#########################################################################"
        echo y | ./byfn.sh -m down
	echo y | ./byfn.sh -m up -c custom_channel_couch -s couchdb -t 60
        copy_logs custom_channel_couch
        echo y | ./byfn.sh -m down
fi
