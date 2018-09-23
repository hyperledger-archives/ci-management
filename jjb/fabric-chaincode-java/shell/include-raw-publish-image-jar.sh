#!/bin/bash -exu
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

######################
# PUBLISH DOCKER IMAGE
######################

ORG_NAME=hyperledger/fabric
NEXUS_URL=nexus3.hyperledger.org:10003
TAG=$GIT_COMMIT &&  COMMIT_TAG=${TAG:0:7}
STABLE_TAG=amd64-$STABLE_VERSION
# Get the Version from build.gradle file
PROJECT_VERSION=$(cat build.gradle | grep "version =" | awk '{print $3}' | tr -d "'")
VERSION=$(echo $PROJECT_VERSION | cut -d- -f 1)

# Build chaincode-javaenv docker image
./gradlew buildImage

echo "========> gradlew build"

# gladlew build from fabric-chaincode-java repo
./gradlew build
# shellcheck disable=SC2046
if [ `echo $PROJECT_VERSION | grep -c "SNAPSHOT" ` -gt 0 ]; then
        # if snapshot
        # tag hyperledger/fabric-javaenv
	docker tag $ORG_NAME-javaenv $NEXUS_URL/$ORG_NAME-javaenv:$STABLE_TAG
	docker tag $ORG_NAME-javaenv $NEXUS_URL/$ORG_NAME-javaenv:$STABLE_TAG-$COMMIT_TAG

	# Push javenv docker image to nexus3
        echo "------> PUSHING"
        docker images
	docker push $NEXUS_URL/$ORG_NAME-javaenv:$STABLE_TAG
	docker push $NEXUS_URL/$ORG_NAME-javaenv:$STABLE_TAG-$COMMIT_TAG

# Publish snapshot to Nexus snapshot URL
    for binary in chaincode-shim chaincode-protos; do
       echo "Pushing fabric-$binary.$PROJECT_VERSION.tar.gz to maven snapshots..."
       cp $WORKSPACE/fabric-$binary/build/libs/fabric-$binary-$VERSION-SNAPSHOT.jar $WORKSPACE/fabric-$binary/build/libs/fabric-$binary.$VERSION.SNAPSHOT.jar
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=$WORKSPACE/fabric-$binary/build/libs/fabric-$binary.$VERSION.SNAPSHOT.jar \
        -DupdateReleaseInfo=true \
        -DrepositoryId=hyperledger-snapshots \
        -Durl=https://nexus.hyperledger.org/content/repositories/snapshots/ \
        -DgroupId=org.hyperledger.fabric \
        -Dversion=$VERSION-SNAPSHOT \
        -DartifactId=fabric-$binary \
        -DgeneratePom=true \
        -DuniqueVersion=false \
        -Dpackaging=jar \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
    done
       echo "========> DONE <======="

else
        # if release

        # Publish docker images to hyperledger dockerhub
        docker tag $ORG_NAME-javaenv $ORG_NAME-javaenv:amd64-$VERSION
        docker push $ORG_NAME-javaenv:amd64-$VERSION

        # Publish chaincode-shim and chaincode-protos to nexus
    for binary in chaincode-shim chaincode-protos; do
       echo "Pushing fabric-$binary.$VERSION.jar to maven releases.."
       cp $WORKSPACE/fabric-$binary/build/libs/fabric-$binary-$VERSION.jar $WORKSPACE/fabric-$binary/build/libs/fabric-$binary.$VERSION.jar
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -DupdateReleaseInfo=true \
        -Dfile=$WORKSPACE/fabric-$binary/build/libs/fabric-$binary.$VERSION.jar \
        -DrepositoryId=hyperledger-releases \
        -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
        -DgroupId=org.hyperledger.fabric \
        -Dversion=$VERSION \
        -DartifactId=fabric-$binary \
        -DgeneratePom=true \
        -DuniqueVersion=false \
        -Dpackaging=jar \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
   done
     echo "========> DONE <======="
fi
