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

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric
ORG_NAME=hyperledger/fabric
NEXUS_URL=nexus3.hyperledger.org:10003
TAG=$GIT_COMMIT &&  COMMIT_TAG=${TAG:0:7}
ARCH=$(go env GOARCH)
echo -e "\033[1;32m--------->ARCH\033[0m" $ARCH
PROJECT_VERSION=$PUSH_VERSION
echo "-----------> PROJECT_VERSION:" $PROJECT_VERSION
STABLE_TAG=$ARCH-$PROJECT_VERSION
echo "-----------> STABLE_TAG:" $STABLE_TAG

fabric_DockerTag() {
    for IMAGES in ${IMAGES_LIST[*]}; do
        echo -e "\033[1m----------> $IMAGES\033[0m"
        echo
        docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
        if [[ "$GERRIT_BRANCH" = "master" ]]; then
            echo "-----> tag latest"
            docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-latest
        fi
    done
        docker images
        echo "----------> $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG"
}

dockerFabricPush() {
    for IMAGES in ${IMAGES_LIST[*]}; do
        echo -e "\033[1m----------> $IMAGES\033[0m"
        docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
        if [[ "$GERRIT_BRANCH" = "master" ]]; then
            echo "-----> push latest"
            docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$ARCH-latest
        fi
        echo
    done
    docker images
    echo "-----------> $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG"
}

if [[ "$GERRIT_BRANCH" = "master" ]]; then
    IMAGES_LIST=(baseos peer orderer ccenv tools)
    fabric_DockerTag  #Tag Fabric Docker Images
    dockerFabricPush  #Push Fabric Docker Images to Nexus3
else
    IMAGES_LIST=(peer orderer ccenv tools)
    fabric_DockerTag  #Tag Fabric Docker Images
    dockerFabricPush  #Push Fabric Docker Images to Nexus3
fi

# Listout all docker images Before and After Push to NEXUS
docker images | grep "nexus*"

echo "------> Current space information."
df -h

# Publish fabric binaries
# Don't publish same binaries if they are available in nexus
if [ $GERRIT_BRANCH = "master" ]; then
    PROJECT_VERSION=latest
else
    PROJECT_VERSION=$PUSH_VERSION
fi

echo "######################"
echo " Publishing Binaries"
echo "######################"
echo
curl -L https://nexus.hyperledger.org/content/repositories/snapshots/org/hyperledger/fabric/hyperledger-fabric-$PROJECT_VERSION > output.xml

if cat output.xml | grep $COMMIT_TAG > /dev/null; then
    echo "--------> INFO: $COMMIT_TAG is already available... SKIP BUILD"
elif [[ $ARCH == "amd64" ]]; then
        # Push fabric-binaries to nexus2
        for binary in linux-amd64 windows-amd64 darwin-amd64 linux-s390x; do
            cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/$binary || exit
        tar -czf hyperledger-fabric-$binary.$PROJECT_VERSION.$COMMIT_TAG.tar.gz *
            echo "----------> Pushing hyperledger-fabric-$binary.$PROJECT_VERSION.tar.gz to maven.."
            mvn -B org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
            -DupdateReleaseInfo=true \
            -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/$binary/hyperledger-fabric-$binary.$PROJECT_VERSION.$COMMIT_TAG.tar.gz \
            -DrepositoryId=hyperledger-snapshots \
            -Durl=https://nexus.hyperledger.org/content/repositories/snapshots/ \
            -DgroupId=org.hyperledger.fabric \
            -Dversion=$binary.$PROJECT_VERSION-SNAPSHOT \
            -DartifactId=hyperledger-fabric-$PROJECT_VERSION \
            -DuniqueVersion=false \
            -Dpackaging=tar.gz \
            -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
            echo "-------> DONE <----------"
            rm -f hyperledger-fabric-$binary.$PROJECT_VERSION.$COMMIT_TAG.tar.gz || true
        done
    else
       echo "-------> Dont publish binaries from s390x or ppc64le platform"
fi
