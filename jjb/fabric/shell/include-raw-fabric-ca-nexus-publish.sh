#!/bin/bash -e
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

ORG_NAME=hyperledger/fabric
ARCH=$(go env GOARCH)
echo -e "\033[1;32m--------->ARCH\033[0m" $ARCH
PROJECT_VERSION=$PUSH_VERSION
echo "-----------> PROJECT_VERSION:" $PROJECT_VERSION
STABLE_TAG=$ARCH-$PROJECT_VERSION
echo "-----------> STABLE_TAG:" $STABLE_TAG
export NEXUS_URL=nexus3.hyperledger.org:10003

fabric_ca_build() {
    FABRIC_CA_WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
    cd $FABRIC_CA_WD
    git checkout $GERRIT_BRANCH
    echo "--------> $GERRIT_BRANCH"
    CA_COMMIT=$(git log -1 --pretty=format:"%h")
    echo "CA COMMIT" $CA_COMMIT

    # Print the last commit
    git log -n1

    # Build fabric-ca images with PROJECT_VERSION and binary
    for IMAGES in docker-fabric-ca $2 release-clean $1; do
        make $IMAGES PROJECT_VERSION=$PUSH_VERSION
    done
}

fabric_ca_tag() {
    for IMAGES in ca $1; do
        echo "----------> $IMAGES"
        echo
        docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
        if [[ "$GERRIT_BRANCH" = "master" ]]; then
            docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-latest
            echo "-----> tag latest"
        fi
    done
    docker images
    echo "----------> $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG"
}

fabric_ca_push() {
    for IMAGES in ca $1; do
        echo "-----------> Push $IMAGES:$STABLE_TAG"
        docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
        if [[ "$GERRIT_BRANCH" = "master" ]]; then
            echo "-----> $IMAGES Push latest"
            docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-latest
        fi
        echo
    done
    docker images
    echo "-----------> $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG"
}

if [[ "$ARCH" = "s390x" || "$ARCH" = "ppc64le" ]]; then
    echo -e "\033[1;32m--------->ARCH\033[0m" $ARCH
    fabric_ca_build
    fabric_ca_tag
    fabric_ca_push
else
    echo -e "\033[1;32m--------->ARCH\033[0m" $ARCH
    fabric_ca_build dist-all docker-fvt
    fabric_ca_tag ca-fvt
    fabric_ca_push ca-fvt
fi

# Listout all docker images Before and After Push to NEXUS
docker images | grep "nexus*"

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
