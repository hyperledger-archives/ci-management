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

# This script publishes the docker images to Nexus3 and binaries to Nexus2 if
# the nightly build is successful.

build_Fabric_Ca() {
    FABRIC_CA_WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"

    cd $FABRIC_CA_WD
    git checkout $GERRIT_BRANCH
    echo "--------> $GERRIT_BRANCH"

    # Print the last commit
    git log -n1
    # Build fabric-ca-client binary
    echo -e "\033[32m ==== Build fabric-ca-client binary ==== \033[0m"
    ARCH=$(go env GOARCH)

    case $ARCH in
        s390x)  echo "---------> fabric-ca-client is not published from $ARCH platform"
        ;;
        amd64) make dist-all
        ;;
        *) echo "---------> fabric-ca-client is not published from $ARCH platform"
           exit 1
        ;;
    esac
}

build_Fabric_Ca

export NEXUS_URL=nexus3.hyperledger.org:10003
ARCH=$(go env GOARCH)
echo "--------->" $ARCH
PROJECT_VERSION=$PUSH_VERSION
echo "-----------> PROJECT_VERSION:" $PROJECT_VERSION
STABLE_TAG=$ARCH-$PROJECT_VERSION
echo "-----------> STABLE_TAG:" $STABLE_TAG

CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "CA COMMIT" $CA_COMMIT

echo "------> Current space information."
df -h

if [[ $GERRIT_BRANCH == "master" ]]; then
    PROJECT_VERSION=latest
else
    PROJECT_VERSION=$PUSH_VERSION
fi

if [[ $ARCH == "amd64" ]]; then
    # Push fabric-ca-binaries to nexus
    for binary in linux-amd64 windows-amd64 darwin-amd64 linux-s390x; do
        cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca/release/$binary
        tar -czf hyperledger-fabric-ca-$binary.$PROJECT_VERSION.$CA_COMMIT.tar.gz *
        echo "----------> Pushing hyperledger-fabric-ca-$binary.$PROJECT_VERSION.$CA_COMMIT.tar.gz to maven.."
        mvn -B org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
            -DupdateReleaseInfo=true \
            -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca/release/$binary/hyperledger-fabric-ca-$binary.$PROJECT_VERSION.$CA_COMMIT.tar.gz \
            -DrepositoryId=hyperledger-snapshots \
            -Durl=https://nexus.hyperledger.org/content/repositories/snapshots/ \
            -DgroupId=org.hyperledger.fabric-ca \
            -Dversion=$binary.$PROJECT_VERSION-SNAPSHOT \
            -DartifactId=hyperledger-fabric-ca-$PROJECT_VERSION \
            -DgeneratePom=true \
            -DuniqueVersion=false \
            -Dpackaging=tar.gz \
            -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
        echo "-------> DONE <----------"
    done
else
        echo "-------> Dont publish binaries from s390x platform"
fi
