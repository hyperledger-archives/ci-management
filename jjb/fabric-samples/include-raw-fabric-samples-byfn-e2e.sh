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

echo "------> BRANCH: " $GERRIT_BRANCH
if [ $GERRIT_BRANCH == "master" ]; then

	echo "############## BYFN,EYFN DEFAULT CHANNEL TEST####################"
	echo "#################################################################"

	echo y | ./byfn.sh -m down
	echo y | ./byfn.sh -m up -t 60
	echo y | ./eyfn.sh -m up -t 60
        echo y | ./eyfn.sh -m down
	echo
	echo "############## BYFN,EYFN CUSTOM CHANNEL TEST#############"
	echo "#########################################################"

	echo y | ./byfn.sh -m up -c fabricrelease -t 60
	echo y | ./eyfn.sh -m up -c fabricrelease -t 60
	echo y | ./eyfn.sh -m down
	echo
	echo "############### BYFN,EYFN CUSTOME CHANNEL WITH COUCHDB TEST #############"
	echo "#########################################################################"

	echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 60
	echo y | ./eyfn.sh -m up -c couchdbtest -s couchdb -t 60
	echo y | ./eyfn.sh -m down
	echo
	echo "############### BYFN,EYFN WITH NODE LANG. TEST ################"
	echo "###############################################################"

	echo y | ./byfn.sh -m up -l node -t 60
	echo y | ./eyfn.sh -m up -l node -t 60
	echo y | ./eyfn.sh -m down

else
	echo "############## BYFN,EYFN DEFAULT CHANNEL TEST####################"
	echo "#################################################################"
	echo y | ./byfn.sh -m down
        echo y | ./byfn.sh -m up -t 60
	echo y | ./byfn.sh -m down
        echo

        echo "############## BYFN,EYFN CUSTOM CHANNEL TEST#############"
        echo "#########################################################"
        echo y | ./byfn.sh -m up -c fabricrelease -t 60

	echo "############### BYFN,EYFN CUSTOME CHANNEL WITH COUCHDB TEST #############"
        echo "#########################################################################"
        echo y | ./byfn.sh -m down
	echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 60
        echo y | ./byfn.sh -m down
fi
