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

echo
echo "Build fabric Chaintool binaries"
echo

make

VERSION=`cat project.clj | grep defproject | awk '{print $3}' | tr -d '"'`
echo "=======> $VERSION"

echo "`cat project.clj | grep defproject | awk '{print $3}' | tr -d '"'`" | tee version.txt
tmp=$(grep -c SNAPSHOT version.txt)
echo
echo "====> $tmp"

if [[ $tmp -gt 0 ]]; then
       echo "===> VERSION SNAPSHOT found"
       echo
       echo "Pushing hyperledger-fabric-chaintool.$VERSION.jar to maven snapshots.."
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=${WORKSPACE}/target/chaintool \
        -DrepositoryId=hyperledger-snapshots \
        -Durl=https://nexus.hyperledger.org/content/repositories/snapshots/ \
        -DgroupId=org.hyperledger.fabric \
        -Dversion=chaintool-$VERSION \
        -DartifactId=hyperledger-fabric \
        -DgeneratePom=true \
        -DuniqueVersion=false \
        -Dpackaging=jar \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
     echo "========> DONE <======="

else
       echo "Pushing hyperledger-fabric-chaintool.$VERSION.jar to maven releases.."
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=${WORKSPACE}/target/chaintool \
        -DrepositoryId=hyperledger-releases \
        -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
        -DgroupId=org.hyperledger.fabric \
        -Dversion=chaintool-$VERSION \
        -DartifactId=hyperledger-fabric \
        -DgeneratePom=true \
        -DuniqueVersion=false \
        -Dpackaging=jar \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
     echo "========> DONE <======="
fi
