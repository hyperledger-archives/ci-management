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
set -o pipefail

ORG_NAME="hyperledger/fabric"
echo "#######################"
echo -e "\033[1m P U L L - T H I R D P A R T Y\033[0m"
echo "#######################"
echo
# tag fabric images
# release-1.2 branch supports amd64 and rest all on x86_64
if [ "$GERRIT_BRANCH" = "release-1.0" ] || [ "$GERRIT_BRANCH" = "release-1.1" ]; then
     MARCH=x86_64
     echo "---------> MARCH: $MARCH"
else
     MARCH=$(dpkg --print-architecture)
     echo "---------> MARCH: $MARCH"
fi
# Fetch the Baseimage release version
if [[ $GERRIT_BRANCH = 'release-1.0' ]]; then
    BASEIMAGE_RELEASE=`cat $WORKSPACE/gopath/src/github.com/hyperledger/fabric/Makefile | grep "PREV_VERSION =" | cut -d " " -f 3`
    echo "------> $BASEIMAGE_RELEASE"
elif [[ $GERRIT_BRANCH = 'master' ]]; then
    BASEIMAGE_RELEASE=`cat $WORKSPACE/gopath/src/github.com/hyperledger/fabric/Makefile | grep "BASEIMAGE_RELEASE =" | cut -d "=" -f 2 | tr -d ' '`
    echo "-----> BASEIMAGE_RELEASE: $BASEIMAGE_RELEASE"
else
    BASEIMAGE_RELEASE=`cat $WORKSPACE/gopath/src/github.com/hyperledger/fabric/Makefile | grep BASEIMAGE_RELEASE= | cut -d "=" -f 2`
    echo "-----> BASEIMAGE_RELEASE: $BASEIMAGE_RELEASE"

fi

dockerTag() {
    for IMAGES in couchdb kafka zookeeper; do
       echo -e "\033[1m==> $IMAGES\033[0m"
       docker pull $ORG_NAME-$IMAGES:$MARCH-$BASEIMAGE_RELEASE
       docker tag $ORG_NAME-$IMAGES:$MARCH-$BASEIMAGE_RELEASE $ORG_NAME-$IMAGES
       echo
    done
}
# Tag Fabric couchdb, kafka and zookeeper docker images
dockerTag

# List out all docker images
docker images | grep "hyperledger*"
