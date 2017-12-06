#!/bin/bash
set -o pipefail

echo
echo "Publish fabric binaries"
echo
export FABRIC_ROOT_DIR=$WORKSPACE/gopath/src/github.com/hyperledger/fabric

cd $FABRIC_ROOT_DIR || exit
make release-clean dist-clean dist-all

BASE_VERSION=`cat Makefile | grep BASE_VERSION | awk '{print $3}' | head -1`
echo "=======> $BASE_VERSION"

# Push fabric-binaries to nexus2

     for binary in linux-amd64 windows-amd64 darwin-amd64 linux-ppc64le linux-s390x; do
       echo "Pushing hyperledger-fabric-$binary.DAILY_STABLE.tar.gz to maven snapshots..."
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/$binary/hyperledger-fabric-$binary.DAILY_STABLE.tar.gz \
        -DrepositoryId=hyperledger-snapshots \
        -Durl=https://nexus.hyperledger.org/content/repositories/snapshots/ \
        -DgroupId=org.hyperledger.fabric \
        -Dversion=$binary-DAILY_STABLE \
        -DartifactId=hyperledger-fabric \
        -DgeneratePom=true \
        -DuniqueVersion=false \
        -Dpackaging=tar.gz \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
     done
     echo "========> DONE <======="
