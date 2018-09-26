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

# RUN END-to-END Tests
######################

# docker container list
CONTAINER_LIST=(peer0.org1 peer1.org1 peer0.org2 peer1.org2 peer0.org3 peer1.org3 orderer)
COUCHDB_CONTAINER_LIST=(couchdb0 couchdb1 couchdb2 couchdb3 couchdb4 couchdb5)

# Create Logs directory
mkdir -p $WORKSPACE/Docker_Container_Logs

vote(){
     ssh -p 29418 hyperledger-jobbuilder@$GERRIT_HOST gerrit review \
          $GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER \
          --notify '"NONE"' \
          "$@"
}

artifacts() {

    echo "---> Archiving generated logs"
    rm -rf $WORKSPACE/archives
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
    vote -m "Failed" -l F2-SmokeTest=-1
    exit 1
fi
}

vote -m '"Starting smoke tests"' -l F2-SmokeTest=0 -l F3-UnitTest=0 -l F3-IntegrationTest=0

NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"

if [[ "$GERRIT_BRANCH" = *"release-"* ]]; then
   MARCH=x86_64
   echo "----------> MARCH:" $MARCH
else
   MARCH=amd64
   echo "----------> MARCH:" $MARCH
fi

TAG=$GIT_COMMIT
export CCENV_TAG=${TAG:0:7}
cd ${GOPATH}/src/github.com/hyperledger/fabric || exit
VERSION=$(make -f Makefile -f <(printf 'p:\n\t@echo $(BASE_VERSION)\n') p)
echo "------> BASE_VERSION = $VERSION"

dockerTag() {
  for IMAGES in peer orderer ccenv tools; do
    echo "==> $IMAGES"
    echo
    docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$CCENV_TAG
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$CCENV_TAG $ORG_NAME-$IMAGES
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$CCENV_TAG"
  done
}

# Tag Fabric Nexus docker images to hyperledger
dockerTag
docker tag $NEXUS_URL/$ORG_NAME-ccenv:$CCENV_TAG $ORG_NAME-ccenv:$MARCH-$VERSION-snapshot-$CCENV_TAG
docker tag $NEXUS_URL/$ORG_NAME-ccenv:$CCENV_TAG $ORG_NAME-ccenv:$MARCH-$VERSION # release-1.1 branch

# List all hyperledger docker images
docker images | grep "hyperledger*"

WD="${GOPATH}/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples
rm -rf $WD

git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
cd $WD || exit
git checkout $GERRIT_BRANCH

FABRIC_SAMPLES_COMMIT=$(git log -1 --pretty=format:"%h")
echo "-------> FABRIC_SAMPLES_COMMIT = $FABRIC_SAMPLES_COMMIT"
curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-build/linux-amd64-$CCENV_TAG/hyperledger-fabric-build-linux-amd64-$CCENV_TAG.tar.gz | tar xz

cd first-network || exit
export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

#Set INFO to DEBUG
sed -it 's/INFO/DEBUG/' base/peer-base.yaml

byfn_Result() {
   if [ $1 = 0 ]; then
        vote -m '"Succeeded, Run UnitTest, Run IntegrationTest"' -l F2-SmokeTest=+1
   else
        vote -m '"Failed"' -l F2-SmokeTest=-1
        exit 1
   fi
}
# Execute below tests

if [ $GERRIT_BRANCH != "release-1.0" ]; then
          echo
          echo "======> DEFAULT CHANNEL <======"
          echo y | ./byfn.sh -m down
          copy_logs $?
          echo y | ./byfn.sh -m generate
          copy_logs $? default-channel
          echo y | ./byfn.sh -m up -t 60
          copy_logs $? default-channel
          echo y | ./eyfn.sh -m up -t 60
          copy_logs $? default-channel
          echo y | ./eyfn.sh -m down
          echo
          echo "======> CUSTOM CHANNEL <======="
          echo y | ./byfn.sh -m generate -c fabricrelease
          copy_logs $? custom-channel
          echo y | ./byfn.sh -m up -c fabricrelease -t 60
          copy_logs $? custom-channel
          echo y | ./eyfn.sh -m up -c fabricrelease -t 60
          copy_logs $? custom-channel
          echo y | ./eyfn.sh -m down

          echo
          echo "======> CouchDB tests <======="

          echo y | ./byfn.sh -m generate -c couchdbtest
          copy_logs $? custom-channel-couch couchdb
          echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 90 -d 15
          copy_logs $? custom-channel-couch couchdb
          echo y | ./eyfn.sh -m up -c couchdbtest -s couchdb -t 90 -d 15
          copy_logs $? custom-channel-couch couchdb
          echo y | ./eyfn.sh -m down
          echo

          echo "======> NODE Chaincode tests <======="
          echo y | ./byfn.sh -m generate -l node
          copy_logs $? default-channel-node
          echo y | ./byfn.sh -m up -l node -t 60
          copy_logs $? default-channel-node
          echo y | ./eyfn.sh -m up -l node -t 60
          copy_logs $? default-channel-node
          echo y | ./eyfn.sh -m down
          byfn_Result $?

else

          echo
          echo "======> DEFAULT CHANNEL <======"

          echo y | ./byfn.sh -m down
          copy_logs $?
          echo y | ./byfn.sh -m generate
          copy_logs $? default-channel
          echo y | ./byfn.sh -m up -t 60
          copy_logs $? default-channel
          echo y | ./byfn.sh -m down

          echo
          echo "======> CUSTOM CHANNEL <======="

          echo y | ./byfn.sh -m generate -c fabricrelease
          copy_logs $? custom-channel
          echo y | ./byfn.sh -m up -c fabricrelease -t 60
          copy_logs $? custom-channel
          echo y | ./byfn.sh -m down

          echo
          echo "======> CouchDB tests <======="

          echo y | ./byfn.sh -m generate -c couchdbtest
          copy_logs $? custom-channel-couchdb couchdb
          echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 60
          copy_logs $? custom-channel-couchdb couchdb
          echo y | ./byfn.sh -m down
          byfn_Result $?

fi
