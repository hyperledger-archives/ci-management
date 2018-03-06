#!/bin/bash -eu

set -o pipefail

# docker container list
CONTAINER_LIST=(peer0.org1 peer1.org2 peer0.org2 peer1.org1 orderer peer0.org3 peer1.org3)

cd gopath/src/github.com/hyperledger/fabric-samples
# copy /bin directory to fabric-samples
cp -r ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/release/linux-amd64/bin/ .

cd first-network

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

# Execute below tests
echo "------> BRANCH: " $GERRIT_BRANCH
if [ $GERRIT_BRANCH == "master" ]; then

	echo "############## BYFN,EYFN DEFAULT CHANNEL TEST####################"
	echo "#################################################################"

	echo y | ./byfn.sh -m down
	echo y | ./byfn.sh -m up -t 60
	echo y | ./eyfn.sh -m up -t 60
        logs mychannel
        echo y | ./eyfn.sh -m down
	echo
	echo "############## BYFN,EYFN CUSTOM CHANNEL TEST#############"
	echo "#########################################################"

	echo y | ./byfn.sh -m up -c fabricrelease -t 60
	echo y | ./eyfn.sh -m up -c fabricrelease -t 60
        logs fabricrelease
	echo y | ./eyfn.sh -m down
	echo
	echo "############### BYFN,EYFN CUSTOME CHANNEL WITH COUCHDB TEST #############"
	echo "#########################################################################"

	echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 60
	echo y | ./eyfn.sh -m up -c couchdbtest -s couchdb -t 60
        logs couchdbteset
	echo y | ./eyfn.sh -m down
	echo
	echo "############### BYFN,EYFN WITH NODE LANG. TEST ################"
	echo "###############################################################"

	echo y | ./byfn.sh -m up -l node -t 60
	echo y | ./eyfn.sh -m up -l node -t 60
        logs node
	echo y | ./eyfn.sh -m down

else
	echo "############## BYFN,EYFN DEFAULT CHANNEL TEST####################"
	echo "#################################################################"
	echo y | ./byfn.sh -m down
        echo y | ./byfn.sh -m up -t 60
        logs mychannel
	echo y | ./byfn.sh -m down
        echo

        echo "############## BYFN,EYFN CUSTOM CHANNEL TEST#############"
        echo "#########################################################"
        echo y | ./byfn.sh -m up -c fabricrelease -t 60
        logs fabricrelease

	echo "############### BYFN,EYFN CUSTOME CHANNEL WITH COUCHDB TEST #############"
        echo "#########################################################################"
        echo y | ./byfn.sh -m down
	echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 60
        logs couchdbtest
        echo y | ./byfn.sh -m down
fi
