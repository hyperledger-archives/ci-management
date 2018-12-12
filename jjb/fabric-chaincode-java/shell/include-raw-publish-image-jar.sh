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
if [ "$GERRIT_BRANCH" = "master" ]; then
     STABLE_VERSION=2.0.0-stable
elif [ "$GERRIT_BRANCH" = "release-1.4" ]; then
     STABLE_VERSION=1.4.0-stable
else
     STABLE_VERSION=1.3.1-stable
fi
STABLE_TAG=amd64-$STABLE_VERSION
# Get the Version from build.gradle file
PROJECT_VERSION=$(cat build.gradle | grep "version =" | awk '{print $3}' | tr -d "'")

# Build chaincode-javaenv docker image
./gradlew buildImage

echo "========> gradlew build"

# gladlew build from fabric-chaincode-java repo
./gradlew build

# gradle publish maven
./gradlew publishToMavenLocal
# shellcheck disable=SC2046
if [ `echo $PROJECT_VERSION | grep -c "SNAPSHOT" ` -gt 0 ]; then
        # if snapshot
        # tag hyperledger/fabric-javaenv
	docker tag $ORG_NAME-javaenv $NEXUS_URL/$ORG_NAME-javaenv:$STABLE_TAG
	docker tag $ORG_NAME-javaenv $NEXUS_URL/$ORG_NAME-javaenv:$STABLE_TAG-$COMMIT_TAG
        if [ "$GERRIT_BRANCH" = "master" ]; then
	   docker tag $ORG_NAME-javaenv $NEXUS_URL/$ORG_NAME-javaenv:amd64-latest
	   docker push $NEXUS_URL/$ORG_NAME-javaenv:amd64-latest
        fi
	# Push javenv docker image to nexus3
        echo "------> PUSHING"
	docker push $NEXUS_URL/$ORG_NAME-javaenv:$STABLE_TAG
	docker push $NEXUS_URL/$ORG_NAME-javaenv:$STABLE_TAG-$COMMIT_TAG

# Publish snapshot to Nexus snapshot URL
    for binary in shim protos; do
       echo "Pushing fabric-chaincode-$binary.$PROJECT_VERSION.tar.gz to maven snapshots..."
       cp $WORKSPACE/fabric-chaincode-$binary/build/libs/fabric-chaincode-$binary-$PROJECT_VERSION.jar $WORKSPACE/fabric-chaincode-$binary/build/libs/fabric-chaincode-$binary.$PROJECT_VERSION.jar
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=$WORKSPACE/fabric-chaincode-$binary/build/libs/fabric-chaincode-$binary.$PROJECT_VERSION.jar \
	-DpomFile=$WORKSPACE/fabric-chaincode-$binary/build/publications/"$binary"Jar/pom-default.xml \
        -DupdateReleaseInfo=true \
        -DrepositoryId=hyperledger-snapshots \
        -Durl=https://nexus.hyperledger.org/content/repositories/snapshots/ \
        -DgroupId=org.hyperledger.fabric-chaincode-java \
        -Dversion=$PROJECT_VERSION \
        -DartifactId=fabric-chaincode-$binary \
        -DgeneratePom=false \
        -DuniqueVersion=false \
        -Dpackaging=jar \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
    done
       echo "========> DONE <======="

else
        # if release

        # Publish docker images to hyperledger dockerhub
        docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
        # tag javaenv image to $PROJECT_VERSION
        docker tag $ORG_NAME-javaenv $ORG_NAME-javaenv:amd64-$PROJECT_VERSION
        # push javaenv to hyperledger dockerhub
        docker push $ORG_NAME-javaenv:amd64-$PROJECT_VERSION

        # Publish chaincode-shim and chaincode-protos to nexus
    for binary in shim protos; do
       echo "Pushing fabric-chaincode-$binary.$PROJECT_VERSION.jar to maven releases.."
       cp $WORKSPACE/fabric-chaincode-$binary/build/libs/fabric-chaincode-$binary-$PROJECT_VERSION.jar $WORKSPACE/fabric-chaincode-$binary/build/libs/fabric-chaincode-$binary.$PROJECT_VERSION.jar
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -DupdateReleaseInfo=true \
        -Dfile=$WORKSPACE/fabric-chaincode-$binary/build/libs/fabric-chaincode-$binary.$PROJECT_VERSION.jar \
	-DpomFile=$WORKSPACE/fabric-chaincode-$binary/build/publications/"$binary"Jar/pom-default.xml \
        -DrepositoryId=hyperledger-releases \
        -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
        -DgroupId=org.hyperledger.fabric-chaincode-java \
        -Dversion=$PROJECT_VERSION \
        -DartifactId=fabric-chaincode-$binary \
        -DgeneratePom=false \
        -DuniqueVersion=false \
        -Dpackaging=jar \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
   done
     echo "========> DONE <======="
fi
