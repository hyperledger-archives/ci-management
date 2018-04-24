#!/bin/bash -e

# This script publishes the docker images to Nexus3 and binaries to Nexus2 if the end-to-end-merge tests are successful.
# Currently the images and binaries are published to Nexus only from the master branch.

if [ $GERRIT_BRANCH != master ]; then
   echo "-------> Publish Images & Binaries only from Master branch <-------"
else
   echo "-------> Publish Images & Binaries from Master branch <-------"
cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric || exit 1

ORG_NAME=hyperledger/fabric
NEXUS_URL=nexus3.hyperledger.org:10003
TAG=$GIT_COMMIT
STABLE_TAG=stable
export COMMIT_TAG=${TAG:0:7}

  dockerTag() {
    for IMAGES in peer orderer ccenv tools ca; do
         echo "==> $IMAGES"
         echo
         docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
         echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG"
    done
    }

  dockerFabricPush() {
    for IMAGES in peer orderer ccenv tools ca; do
         echo "==> $IMAGES"
         docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
         echo
         echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG"
    done
    }

# Tag Fabric Docker Images to Nexus Repository
dockerTag
# Push Fabric Docker Images to Nexus Repository
dockerFabricPush
# Listout all docker images Before and After Push to NEXUS
docker images | grep "nexus*"

binary=linux-amd64
 make release-clean dist-clean
 make dist
     if [ $? = 0 ]; then
                       # Push fabric-binaries to nexus2
                       cd release/$binary && tar -czf hyperledger-fabric-$binary.stable.$COMMIT_TAG.tar.gz *
                       echo "Pushing hyperledger-fabric-$binary.stable.$COMMIT_TAG.tar.gz to maven.."
                       mvn -B org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
                       -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/$binary/hyperledger-fabric-$binary.stable.$COMMIT_TAG.tar.gz \
                       -DrepositoryId=hyperledger-releases \
                       -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
                       -DgroupId=org.hyperledger.fabric \
                       -Dversion=$binary-stable-$COMMIT_TAG \
                       -DartifactId=hyperledger-fabric-stable \
                       -DgeneratePom=true \
                       -DuniqueVersion=false \
                       -Dpackaging=tar.gz \
                       -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
                       echo "-------> DONE <----------"
     else
                       echo "-------> make dist failed"
                       exit 1
     fi
fi
