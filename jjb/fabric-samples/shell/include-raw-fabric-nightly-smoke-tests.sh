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

# Clone fabric-samples.
######################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples
wd="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples"
repo_name=fabric-samples

echo "######## Cloning fabric-samples ########"
git clone git://cloud.hyperledger.org/mirror/$repo_name $wd
cd $wd || exit
git checkout $GERRIT_BRANCH
echo "-------> GERRIT_BRANCH: $GERRIT_BRANCH"
fabric_samples_commit=$(git log -1 --pretty=format:"%h")
echo "FABRIC_SAMPLES_COMMIT ========> $fabric_samples_commit" >> \
  ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log

# copy /bin directory to fabric-samples

if [[ "$ARCH" == "s390x" ]]; then
    cp -r $WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/linux-s390x/bin/ .
elif [[ "$ARCH" == "ppc64le" ]]; then
    cp -r $WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/linux-ppc64le/bin/ .
else
    cp -r $WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/linux-amd64/bin/ .
fi

cd first-network || exit

# Create Logs directory
mkdir -p $WORKSPACE/Docker_Container_Logs

#Set INFO to DEBUG
sed -it 's/INFO/DEBUG/g' base/peer-base.yaml

export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

artifacts() {

    echo "---> Archiving generated logs"
    rm -rf $WORKSPACE/archives
    mkdir -p "$WORKSPACE/archives"
    mv "$WORKSPACE/Docker_Container_Logs" $WORKSPACE/archives/
}

# Capture docker logs of each container
logs() {

    echo -e "\n ===== Collecting logs for test =======\n"
    for container in ${container_list[*]}; do
        docker logs $container.example.com >& $WORKSPACE/Docker_Container_Logs/$container-$1.log
        echo
    done

    if [[ -n $2 ]]; then
        for container in ${couchdb_container_list[*]}; do
            docker logs $container >& $WORKSPACE/Docker_Container_Logs/$container-$1.log
            echo
        done
    fi
}

copy_logs() {

    # Call logs function
    if [[ "$#" -gt 0 ]]; then
        for arg in "$@"; do
            logs $arg
        done
    fi

    if [[ $1 != 0 ]]; then
        artifacts
        exit 1
    fi
}

# Delete existing docker containers
echo "------> Deleting Containers...."
# shellcheck disable=SC2046
docker rm -f $(docker ps -aq) || true
echo "------> List Docker Containers"
docker ps -aq

# Execute BYFN tests
echo "------> BRANCH: " $GERRIT_BRANCH
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

if [[ $GERRIT_BRANCH = "master" && $ARCH = "s390x" ]]; then
    defaultchannel
    customchannel
    nodechaincode
else
    defaultchannel
    customchannel
    couchdb
    nodechaincode
fi
