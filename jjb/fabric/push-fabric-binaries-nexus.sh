#!/bin/bash
set -o pipefail

echo
echo "Publish fabric binaries"
echo
export FABRIC_ROOT_DIR=$WORKSPACE/gopath/src/github.com/hyperledger/fabric
binary=linux-amd64
cd $FABRIC_ROOT_DIR || exit
make release-clean dist-clean dist-all

# Push fabric-binaries to nexus2
     cd release/$binary && tar -czf hyperledger-fabric-$binary.$GIT_COMMIT.tar.gz *
     cd $FABRIC_ROOT_DIR || exit
     echo "Pushing hyperledger-fabric-$binary.$GIT_COMMIT.tar.gz to maven.."
       mvn -B org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/$binary/hyperledger-fabric-$binary.$GIT_COMMIT.tar.gz \
        -DrepositoryId=hyperledger-releases \
        -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
	-DgroupId=org.hyperledger.fabric \
        -Dversion=$binary-$GIT_COMMIT \
        -DartifactId=hyperledger-fabric-build \
        -DgeneratePom=true \
        -DuniqueVersion=false \
        -Dpackaging=tar.gz \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
     echo "========> DONE <======="
