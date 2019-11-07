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

# docker container list
container_list=(peer0.org1 peer1.org1 peer0.org2 peer1.org2 peer0.org3 peer1.org3 orderer)
couchdb_container_list=(couchdb0 couchdb1 couchdb2 couchdb3 couchdb4 couchdb5)

cd gopath/src/github.com/hyperledger/fabric-samples || exit
# copy /bin directory to fabric-samples
echo "######################"
echo -e "\033[1m B Y F N - T E S T S\033[0m"
echo "######################"

cp -r $WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/linux-amd64/bin/ .
cd first-network || exit

# Create Logs directory
mkdir -p $WORKSPACE/Docker_Container_Logs

#Set INFO to DEBUG
sed -it 's/INFO/DEBUG/' base/peer-base.yaml

export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH
echo "------> Deleting Containers...."
# shellcheck disable=SC2046
docker rm -f $(docker ps -aq)
echo "------> List Docker Containers"
docker ps -aq
echo "\n------> BRANCH: $GERRIT_BRANCH\n"

artifacts() {

    echo "---> Archiving generated logs"
    rm -rf $WORKSPACE/archives
    mkdir -p "$WORKSPACE/archives"
    cp -r "$WORKSPACE/Docker_Container_Logs" $WORKSPACE/archives/
}

# Capture docker logs of each container
logs() {

    for container in ${container_list[*]}; do
        docker logs $container.example.com >& $WORKSPACE/Docker_Container_Logs/$container-$1.log
        echo
    done

    if [ ! -z $2 ]; then

        for container in ${couchdb_container_list[*]}; do
            docker logs $container >& $WORKSPACE/Docker_Container_Logs/$container-$1.log
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

# BYFN tests

defaultchannel() {
    echo -e "############## \033[1mD E F A U L T-C H A N N E L\033[0m ###########"
    echo "#########################################################"
    set -x
    echo y | ./byfn.sh -m down
    echo y | ./byfn.sh -m up -t 120 -d 20; copy_logs $? default-channel
    echo y | ./eyfn.sh -m up -t 120 -d 20; copy_logs $? default-channel
    echo y | ./eyfn.sh -m down
    set +x
    echo
}
customchannel() {
    echo -e "############## \033[1mC U S T O M-C H A N N E L\033[0m ################"
    echo "#########################################################"
    set -x
    echo y | ./byfn.sh -m up -c custom-channel -t 120 -d 20; copy_logs $? custom-channel
    echo y | ./eyfn.sh -m up -c custom-channel -t 120 -d 20; copy_logs $? custom-channel
    echo y | ./eyfn.sh -m down
    set +x
    echo
}
couchdb() {
    echo -e "############### \033[1mC O U C H D B-T E S T\033[0m ###################################"
    echo "#########################################################################"
    set -x
    echo y | ./byfn.sh -m up -c custom-channel-couchdb -s couchdb -t 100 -d 20; copy_logs $? custom-channel-couch couchdb
    echo y | ./eyfn.sh -m up -c custom-channel-couchdb -s couchdb -t 100 -d 20; copy_logs $? custom-channel-couch couchdb
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
}
javascriptchaincode() {
    echo -e "############### \033[1mJ A V A S C R I P T-C H A I N C O D E\033[0m ################"
    echo "####################################################################"
    set -x
    echo y | ./byfn.sh -m up -l javascript -t 60; copy_logs $? default-channel-javascript
    echo y | ./eyfn.sh -m up -l javascript -t 60; copy_logs $? default-channel-javascript
    echo y | ./eyfn.sh -m down
    set +x
}
defaultchannelverbose() {
    echo -e "############## \033[1mD E F A U L T-C H A N N E L\033[0m ###########"
    echo "#########################################################"
    set -x
    echo y | ./byfn.sh -m down
    echo y | ./byfn.sh -m up -v -t 120 -d 20; copy_logs $? default-channel
    echo y | ./eyfn.sh -m up -t 120 -d 20; copy_logs $? default-channel
    echo y | ./eyfn.sh -m down
    set +x
    echo
}
customchannelraft() {
    echo -e "############## \033[1mC U S T O M-C H A N N E L-R A F T\033[0m ################"
    echo "#########################################################"
    set -x
    echo y | ./byfn.sh -m up -c custom-channel-etcdraft -t 120 -d 20; copy_logs $? custom-channel-etcdraft
    echo y | ./eyfn.sh -m up -c custom-channel-etcdraft -t 120 -d 20; copy_logs $? custom-channel-etcdraft
    echo y | ./eyfn.sh -m down
    set +x
    echo
}
customchannelraft1.4() {
    echo -e "############## \033[1mC U S T O M-C H A N N E L-R A F T\033[0m ################"
    echo "#########################################################"
    set -x
    echo y | ./byfn.sh -m up -o etcdraft -c custom-channel-etcdraft -t 120 -d 20; copy_logs $? custom-channel-etcdraft
    echo y | ./eyfn.sh -m up -c custom-channel-etcdraft -t 120 -d 20; copy_logs $? custom-channel-etcdraft
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
  "release-1.1" | "release-1.2" | "release-1.3")
    defaultchannel
    customchannel
    couchdb
    nodechaincode
    ;;
  release-1.4)
    defaultchannelverbose
    customchannelraft1.4
    couchdb
    nodechaincode
    ;;
  master)
    defaultchannelverbose
    customchannelraft
    javascriptchaincode
    ;;
  *) echo "ERROR: Unknown Gerrit Branch: $GERRIT_BRANCH" ; exit 1;;
esac
