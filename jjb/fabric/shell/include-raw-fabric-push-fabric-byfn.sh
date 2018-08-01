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

echo "=======>"
echo "=======>"
echo
echo "Publish fabric byfn"
echo
export FABRIC_ROOT_DIR=$WORKSPACE/gopath/src/github.com/hyperledger/fabric

cd $FABRIC_ROOT_DIR || exit

BASE_VERSION=`cat Makefile | grep BASE_VERSION | awk '{print $3}' | head -1`
echo "=============> $BASE_VERSION"

COMMIT_VERSION=$(git rev-parse --short HEAD)
echo "=============> $COMMIT_VERSION"

IS_RELEASE=`cat Makefile | grep IS_RELEASE | awk '{print $3}'`
echo "=======>" $IS_RELEASE

if [ "${IS_RELEASE}" == "false" ]; then

       cd $FABRIC_ROOT_DIR/examples/byfn || exit
       mkdir -p channel-artifacts
       tar -czf hyperledger-fabric-byfn-$BASE_VERSION-snapshot.tar.gz *
       echo "Pushing hyperledger-fabric-byfn-$BASE_VERSION-snapshot.tar.gz to maven snapshots..."
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/hyperledger-fabric-byfn-$BASE_VERSION-snapshot.tar.gz \
        -DrepositoryId=hyperledger-snapshots \
        -Durl=https://nexus.hyperledger.org/content/repositories/snapshots/ \
        -DgroupId=org.hyperledger.fabric \
        -Dversion=$BASE_VERSION-SNAPSHOT \
        -DartifactId=examples \
        -DgeneratePom=true \
        -DuniqueVersion=false \
        -Dpackaging=tar.gz \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
     echo "========> DONE <======="
  else
       cd $FABRIC_ROOT_DIR/examples/byfn || exit
       mkdir -p channel-artifacts
       tar -czf hyperledger-fabric-byfn-$BASE_VERSION.tar.gz *
       echo "Pushing hyperledger-fabric-byfn-$BASE_VERSION.tar.gz to maven releases..."
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/hyperledger-fabric-byfn-$BASE_VERSION.tar.gz \
        -DrepositoryId=hyperledger-releases \
        -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
        -DgroupId=org.hyperledger.fabric \
        -Dversion=$BASE_VERSION \
        -DartifactId=examples \
        -DgeneratePom=true \
        -DuniqueVersion=false \
        -Dpackaging=tar.gz \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
     echo "========> DONE <======="
fi
