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

######################
# PUBLISH DOCKER IMAGE
######################

#ORG_NAME=hyperledger/fabric-chaincode-java
NEXUS_REPO_URL=nexus3.hyperledger.org:10002

# Clone fabric-chaincode-java git repository
clone_Repo() {
  rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-chaincode-java
  WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-chaincode-java"
  REPO_NAME=fabric-chaincode-java
  git clone --single-branch -b $GERRIT_BRANCH https://github.com/hyperledger/$REPO_NAME $WD
  cd $WD && git checkout $GERRIT_BRANCH && git checkout $RELEASE_COMMIT
  # Checkout to the branch and checkout to release commit
  # Provide the value to release commit from Jenkins parameter
  echo "-------> INFO: RELEASE_COMMIT" $RELEASE_COMMIT
}

build_Images() {
  echo "========> gradlew build"
  # gladlew build from fabric-chaincode-java repo
  ./gradlew build

  # gradle publish maven
  ./gradlew publishToMavenLocal
}

publish_Images_Dockerhub() {
  # Publish docker images to hyperledger dockerhub
  docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
  # tag javaenv image to $PUSH_VERSION
  docker tag hyperledger/fabric-javaenv hyperledger/fabric-javaenv:amd64-$PUSH_VERSION
  # push javaenv to hyperledger dockerhub
  docker push hyperledger/fabric-javaenv:amd64-$PUSH_VERSION
}

publish_Images_Nexus() {
  # Publish docker images to nexus repository
  docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
  # tag javaenv image to $PUSH_VERSION
  docker tag hyperledger/fabric-javaenv $NEXUS_REPO_URL/hyperledger/fabric-javaenv:amd64-$PUSH_VERSION
  # push javaenv to nexus repository
  docker push $NEXUS_REPO_URL/hyperledger/fabric-javaenv:amd64-$PUSH_VERSION
}

publish_Jar_Nexus() {
   # Publish chaincode-shim and chaincode-protos to nexus
  for binary in shim protos; do
    echo "Pushing fabric-chaincode-$binary.$PUSH_VERSION.jar to maven releases.."
    cp $WORKSPACE/fabric-chaincode-$binary/build/libs/fabric-chaincode-$binary-$PUSH_VERSION.jar $WORKSPACE/fabric-chaincode-$binary/build/libs/fabric-chaincode-$binary.$PUSH_VERSION.jar
    $MVN org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
     -DupdateReleaseInfo=true \
     -Dfile=$WORKSPACE/fabric-chaincode-$binary/build/libs/fabric-chaincode-$binary.$PUSH_VERSION.jar \
     -DpomFile=$WORKSPACE/fabric-chaincode-$binary/build/publications/"$binary"Jar/pom-default.xml \
     -DrepositoryId=hyperledger-releases \
     -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
     -DgroupId=org.hyperledger.fabric-chaincode-java \
     -Dversion=$PUSH_VERSION \
     -DartifactId=fabric-chaincode-$binary \
     -DgeneratePom=false \
     -DuniqueVersion=false \
     -Dpackaging=jar \
     -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
  done
    echo "========> DONE <======="
}

release_Javaenv() {
  echo -e "\033[32m Clone fabric-chaincode-java git repository" "\033[0m"
  clone_Repo
  echo -e "\033[32m Build javaenv" "\033[0m"
  build_Images
  echo -e "\033[32m Publish images to dockerhub" "\033[0m"
  publish_Images_Dockerhub
  echo -e "\033[32m Publish images to nexus" "\033[0m"
  publish_Images_Nexus
  # echo -e "\033[32m Publish jar to nexus" "\033[0m"
  # publish_Jar_Nexus
}

release_Javaenv
