#!/bin/bash -e

# This script publishes the docker images to Nexus3 and binaries to Nexus2 if the end-to-end-merge tests are successful.
# Currently the images and binaries are published to Nexus only from the master branch.

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric || exit 1
ORG_NAME=hyperledger/fabric
NEXUS_URL=nexus3.hyperledger.org:10003
TAG=$GIT_COMMIT &&  COMMIT_TAG=${TAG:0:7}
ARCH=$(go env GOARCH) && echo "--------->" $ARCH
PROJECT_VERSION=1.2.0-stable
echo "-----------> PROJECT_VERSION:" $PROJECT_VERSION
STABLE_TAG=$ARCH-$PROJECT_VERSION
echo "-----------> STABLE_TAG:" $STABLE_TAG

dockerTag() {
    for IMAGES in peer orderer ccenv tools ca ca-peer ca-orderer ca-tools; do
         echo "----------> $IMAGES"
         echo
         docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
         echo "----------> $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG"
    done
    }

dockerFabricPush() {
    for IMAGES in peer orderer ccenv tools ca ca-peer ca-orderer ca-tools; do
         echo "-----------> $IMAGES"
         docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG
         echo
         echo "-----------> $NEXUS_URL/$ORG_NAME-$IMAGES:$STABLE_TAG"
    done
    }

# Tag Fabric Docker Images to Nexus Repository
dockerTag
# Push Fabric Docker Images to Nexus Repository
dockerFabricPush
# Listout all docker images Before and After Push to NEXUS
docker images | grep "nexus*"

if [ $ARCH = "amd64" ]; then
       # Push fabric-binaries to nexus2
       for binary in linux-amd64 windows-amd64 darwin-amd64 linux-ppc64le linux-s390x; do
              cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/$binary && tar -czf hyperledger-fabric-$binary.$PROJECT_VERSION.$COMMIT_TAG.tar.gz *
              echo "----------> Pushing hyperledger-fabric-$binary.$PROJECT_VERSION.$COMMIT_TAG.tar.gz to maven.."
              mvn -B org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
              -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/$binary/hyperledger-fabric-$binary.$PROJECT_VERSION.$COMMIT_TAG.tar.gz \
              -DrepositoryId=hyperledger-releases \
              -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
              -DgroupId=org.hyperledger.fabric \
              -Dversion=$binary.$PROJECT_VERSION-$COMMIT_TAG \
              -DartifactId=hyperledger-fabric-stable \
              -DgeneratePom=true \
              -DuniqueVersion=false \
              -Dpackaging=tar.gz \
              -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
              echo "-------> DONE <----------"
       done
else
       echo "-------> Don't publish binaries from s390x platform"
fi
