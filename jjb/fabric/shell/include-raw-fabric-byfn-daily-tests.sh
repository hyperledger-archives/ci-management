#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 IBM Corporation, The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License 2.0
# which accompanies this distribution, and is available at
# https://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# RUN BYFN END-to-END Tests
######################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples

# Docker Container list
CONTAINER_LIST=(peer0.org1 peer1.org1 peer0.org2 peer1.org2 peer0.org3 peer1.org3 orderer)
COUCHDB_CONTAINER_LIST=(couchdb0 couchdb1 couchdb2 couchdb3 couchdb4 couchdb5)

git clone https://github.com/hyperledger/$REPO_NAME.git $WD
cd $WD || exit
git checkout $GERRIT_BRANCH
echo "-------> GERRIT_BRANCH: $GERRIT_BRANCH"
FABRIC_SAMPLES_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC_SAMPLES_COMMIT ========> $FABRIC_SAMPLES_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
# copy /bin directory to fabric-samples
cp -r ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/release/linux-amd64/bin/ .

# Create Logs directory
mkdir -p $WORKSPACE/Docker_Container_Logs

echo "######################"
echo -e "\033[1m B Y F N - T E S T S\033[0m"
echo "######################"
echo
cd first-network || exit
#Set INFO to DEBUG
sed -it 's/INFO/DEBUG/' base/peer-base.yaml
export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

artifacts() {

    echo "---> Archiving generated logs"
    rm -rf $WORKSPACE/archives
    mkdir -p "$WORKSPACE/archives"
    cp -r "$WORKSPACE/Docker_Container_Logs" $WORKSPACE/archives/
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

defaultchannel() {
    echo -e "############## \033[1mD E F A U L T-C H A N N E L\033[0m ###########"
    echo "#########################################################"
    set -x
    echo y | ./byfn.sh -m down
    echo y | ./byfn.sh -m up -t 60; copy_logs $? default-channel
    echo y | ./eyfn.sh -m up -t 60; copy_logs $? default-channel
    echo y | ./eyfn.sh -m down
    set +x
    echo
}
customchannel() {
    echo -e "############## \033[1mC U S T O M-C H A N N E L\033[0m ################"
    echo "#########################################################"
    set -x
    echo y | ./byfn.sh -m up -c custom-channel -t 60; copy_logs $? custom-channel
    echo y | ./eyfn.sh -m up -c custom-channel -t 60; copy_logs $? custom-channel
    echo y | ./eyfn.sh -m down
    set +x
    echo
}
couchdb() {
    echo -e "############### \033[1mC O U C H D B-T E S T\033[0m ###################################"
    echo "#########################################################################"
    set -x
    echo y | ./byfn.sh -m up -c custom-channel-couchdb -s couchdb -t 60 -d 15; copy_logs $? custom-channel-couch couchdb
    echo y | ./eyfn.sh -m up -c custom-channel-couchdb -s couchdb -t 60 -d 15; copy_logs $? custom-channel-couch couchdb
    echo y | ./eyfn.sh -m down
    set +x
    echo
}
nodechaincode() {
    echo -e "############### \033[1mN O D E-C H A I N C O D E\033[0m ################"
    echo "####################################################################"
    set -x
    echo y | ./byfn.sh -m up -l node -t 60; copy_logs $? default-channel-node
    echo y | ./eyfn.sh -m up -l node -t 60; copy_logs $? default-channel-node
    echo y | ./eyfn.sh -m down
    set +x
    echo
}
javascriptchaincode() {
    echo -e "############### \033[1mJ A V A S C R I P T-C H A I N C O D E\033[0m ################"
    echo "####################################################################"
    set -x
    echo y | ./byfn.sh -m up -l javascript -t 60; copy_logs $? default-channel-javascript
    echo y | ./eyfn.sh -m up -l javascript -t 60; copy_logs $? default-channel-javascript
    echo y | ./eyfn.sh -m down
    set +x
    echo
}
defaultchannel1.0() {
    echo -e "############## \033[1mD E F A U L T-C H A N N E L\033[0m#########################"
    echo "#################################################################"
    set -x
    echo y | ./byfn.sh -m down
    echo y | ./byfn.sh -m up -t 60; copy_logs $? default-channel
    echo y | ./byfn.sh -m down
    set +x
    echo
}
customchannel1.0() {
    echo -e "############## \033[1mC U S T O M-C H A N N E L\033[0m #################"
    echo "#########################################################"
    set -x
    echo y | ./byfn.sh -m up -c custom-channel -t 60; copy_logs $? custom-channel
    set +x
}
couchdb1.0() {
    echo -e "############### \033[1mC O U C H D B-T E S T\033[0m ###################"
    echo "#########################################################################"
    set -x
    echo y | ./byfn.sh -m down
    echo y | ./byfn.sh -m up -c custom-channel-couchdb -s couchdb -t 60; copy_logs $? custom-channel-couchdb couchdb
    echo y | ./byfn.sh -m down
    set +x
}
# Execute the BYFN,EYFN tests
case $GERRIT_BRANCH in
  release-1.0)
    defaultchannel1.0
    customchannel1.0
    couchdb1.0
    ;;
  "release-1.1" | "release-1.2" | "release-1.3" | "release-1.4")
    defaultchannel
    customchannel
    couchdb
    nodechaincode
    ;;
  master)
    defaultchannel
    customchannel
    couchdb
    javascriptchaincode
    ;;
  *) echo "ERROR: Unknown Gerrit Branch: $GERRIT_BRANCH" ; exit 1;;
esac
