#!/bin/bash -eu
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
set -o pipefail

# Clone fabric git repository
#############################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
REPO_NAME=fabric
git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
cd $WD
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC_COMMIT ========> $FABRIC_COMMIT" >> commit_history.log
mv commit_history.log ${WORKSPACE}/gopath/src/github.com/hyperledger/

# export fabric go version

GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
OS_VER=$(dpkg --print-architecture)
echo "-----> ARCH: $OS_VER"
export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
export PATH=$GOROOT/bin:$PATH
echo "----> GO_VER" $GO_VER
set +e
BRANCH_NAME=$(echo $GERRIT_BRANCH | grep 'release-')
echo "-----> $BRANCH_NAME"
if [ ! -z "$BRANCH_NAME" ]; then

     for IMAGES in docker release; do
        make $IMAGES
        if [ $? != 0 ]; then
           echo "-------> make $IMAGES failed"
           exit 1
        fi
     done

else

     for IMAGES in docker release-clean release; do
        make $IMAGES
        if [ $? != 0 ]; then
           echo "-----> make $IMAGES failed"
           exit 1
        fi
     done

fi

docker images | grep hyperledger
set -e
# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone git://cloud.hyperledger.org/mirror/$CA_REPO_NAME $WD
cd $WD
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "CA COMMIT ========> $CA_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit_history.log

# export fabric-ca go version

GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
OS_VER=$(dpkg --print-architecture)
echo "-----> ARCH: $OS_VER"
export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
export PATH=$GOROOT/bin:$PATH
echo "----> GO_VER" $GO_VER

make docker-fabric-ca

if [ $? != 0 ]; then
   echo "-----> make docker-fabric-ca failed"
   exit 1
fi

docker images | grep hyperledger
