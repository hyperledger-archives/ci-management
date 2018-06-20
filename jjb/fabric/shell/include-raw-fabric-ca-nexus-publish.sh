#!/bin/bash -e

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca || exit 1
ORG_NAME=hyperledger/fabric
export ORG_NAME
PROJECT_VERSION=1.2.0-stable
export PROJECT_VERSION
echo "-----------> PROJECT_VERSION:" $PROJECT_VERSION
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "CA COMMIT" $CA_COMMIT
ARCH=$(go env GOARCH) && echo "--------->" $ARCH

if [ $ARCH = "amd64" ]; then
       # Push fabric-ca-binaries to nexus2
       for binary in linux-amd64 windows-amd64 darwin-amd64 linux-ppc64le linux-s390x; do
              cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca/release/$binary && tar -czf hyperledger-fabric-ca-$binary.$PROJECT_VERSION.$COMMIT_TAG.tar.gz *
              echo "----------> Pushing hyperledger-fabric-ca-$binary.$PROJECT_VERSION.$COMMIT_TAG.tar.gz to maven.."
              mvn -B org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
              -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca/release/$binary/hyperledger-fabric-ca-$binary.$PROJECT_VERSION.$COMMIT_TAG.tar.gz \
              -DrepositoryId=hyperledger-releases \
              -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
              -DgroupId=org.hyperledger.fabric-ca \
              -Dversion=$binary.$PROJECT_VERSION-$COMMIT_TAG \
              -DartifactId=hyperledger-fabric-ca-stable \
              -DgeneratePom=true \
              -DuniqueVersion=false \
              -Dpackaging=tar.gz \
              -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
              echo "-------> DONE <----------"
       done
else
       echo "-------> Don't publish binaries from s390x platform"
fi
