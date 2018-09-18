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

# This script publishes the fabric-ca binaries to Nexus2 if
# the nightly build is successful.

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca || exit 1
git checkout $GERRIT_BRANCH
echo "--------> $GERRIT_BRANCH"
ARCH=$(go env GOARCH)
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "---------> FABRIC_CA_COMMIT : $CA_COMMIT"
echo "CA COMMIT ------> $CA_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log

PROJECT_VERSION=$PUSH_VERSION
echo "-----------> PROJECT_VERSION:" $PROJECT_VERSION
STABLE_TAG=$ARCH-$PROJECT_VERSION
echo "-----------> STABLE_TAG:" $STABLE_TAG

build_Fabric_Ca() {
       #### Build fabric-ca docker images
       for IMAGES in docker $2 release-clean $1; do
           make $IMAGES PROJECT_VERSION=$PUSH_VERSION
           if [ $? != 0 ]; then
               echo "-------> make $IMAGES failed"
               exit 1
           fi
               echo
               echo "-------> List fabric-ca Binary"
       done
}
docker images | grep hyperledger/fabric-ca

fabric_Ca_DockerTag() {
    for IMAGES in ca ca-peer ca-orderer ca-tools $1; do
         echo "----------> $IMAGES"
         echo
         docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
         docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG-$CA_COMMIT
    done
         echo "----------> $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG"
}

dockerFabricCaPush() {
    for IMAGES in ca ca-peer ca-orderer ca-tools $1; do
         echo "-----------> $IMAGES"
         docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
         docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG-$CA_COMMIT
         echo
    done
         echo "-----------> $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG"
}

# Tag Fabric Ca Docker Images
if [ $ARCH = s390x ]; then
    fabric_Ca_DockerTag
else
    fabric_Ca_DockerTag ca-fvt
fi

# Push Fabric Ca Docker Images to Nexus3
if [ $ARCH = s390x ]; then
    dockerFabricCaPush
else
    dockerFabricCaPush ca-fvt
fi
# Listout all docker images Before and After Push to NEXUS
if ! docker images | grep "nexus" ; then
    echo "------> No nexus images"
else
    docker images | grep "nexus*"
fi
# Execute release-all target on x arch
if [ "$ARCH" = "s390x" ]; then
       echo "---------> ARCH:" $ARCH
       build_Fabric_Ca release
else
       echo "---------> ARCH:" $ARCH
       build_Fabric_Ca dist-all
fi

# Publish fabric-ca binaries
curl -L https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric-ca/hyperledger-fabric-ca-$PROJECT_VERSION > output.xml
# shellcheck disable=SC2034
CA_RELEASE_COMMIT=$(cat output.xml | grep $CA_COMMIT)
if [ $? != 1 ]; then
    echo "--------> INFO: $CA_COMMIT is already available... SKIP BUILD"
else
   if [ $ARCH = "amd64" ]; then
       # Push fabric-binaries to nexus2
          for binary in linux-amd64 windows-amd64 darwin-amd64 linux-s390x; do
                 cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca/release/$binary && tar -czf hyperledger-fabric-ca-$binary.$PROJECT_VERSION.$CA_COMMIT.tar.gz *
                 echo "----------> Pushing hyperledger-fabric-ca-$binary.$PROJECT_VERSION.$CA_COMMIT.tar.gz to maven.."
                 mvn -B org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
                 -DupdateReleaseInfo=true \
                 -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca/release/$binary/hyperledger-fabric-ca-$binary.$PROJECT_VERSION.$CA_COMMIT.tar.gz \
                 -DrepositoryId=hyperledger-releases \
                 -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
                 -DgroupId=org.hyperledger.fabric-ca \
                 -Dversion=$binary.$PROJECT_VERSION-$CA_COMMIT \
                 -DartifactId=hyperledger-fabric-ca-$PROJECT_VERSION \
                 -DgeneratePom=true \
                 -DuniqueVersion=false \
                 -Dpackaging=tar.gz \
                 -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
                 echo "-------> DONE <----------"
		 rm -f hyperledger-fabric-$binary.$PROJECT_VERSION.$COMMIT_TAG.tar.gz || true
          done
   else
          echo "-------> Dont publish binaries from s390x platform"
   fi
fi
