#!/bin/bash
set -o pipefail

echo "=======>"
echo "=======>"
echo
echo "Publish fabric binaries"
echo
export FABRIC_ROOT_DIR=$WORKSPACE/gopath/src/github.com/hyperledger/fabric

cd $FABRIC_ROOT_DIR || exit
make release-clean dist-clean dist-all

BASE_VERSION=`cat Makefile | grep BASE_VERSION | awk '{print $3}' | head -1`
echo "=============> $BASE_VERSION"

COMMIT_VERSION=$(git rev-parse --short HEAD)
echo "=============> $COMMIT_VERSION"

IS_RELEASE=`cat Makefile | grep IS_RELEASE | awk '{print $3}'`
echo "=======>" $IS_RELEASE

if [ "${IS_RELEASE}" == "false" ]; then

# copy byfn folder to release/$binary
     for binary in linux-amd64 windows-amd64 darwin-amd64 linux-ppc64le linux-s390x; do
       echo "Pushing hyperledger-fabric-$binary-$BASE_VERSION-snapshot.tar.gz to maven snapshots..."
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/hyperledger-fabric-$binary-$BASE_VERSION-snapshot.tar.gz \
        -DrepositoryId=hyperledger-snapshots \
        -Durl=https://nexus.hyperledger.org/content/repositories/snapshots/ \
        -DgroupId=org.hyperledger.fabric \
        -Dversion=$binary-$BASE_VERSION-SNAPSHOT \
        -DartifactId=fabric-binary \
        -DgeneratePom=true \
        -DuniqueVersion=false \
        -Dpackaging=tar.gz \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
     done
     echo "========> DONE <======="
  else
     for binary in linux-amd64 windows-amd64 darwin-amd64 linux-ppc64le linux-s390x; do
       echo "Pushing hyperledger-fabric-$binary-$BASE_VERSION.tar.gz to maven releases.."
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/hyperledger-fabric-$binary-$BASE_VERSION.tar.gz \
        -DrepositoryId=hyperledger-releases \
        -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
        -DgroupId=org.hyperledger.fabric \
        -Dversion=$binary-$BASE_VERSION \
        -DartifactId=fabric-binary \
        -DgeneratePom=true \
        -DuniqueVersion=false \
        -Dpackaging=tar.gz \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
   done
     echo "========> DONE <======="
fi
