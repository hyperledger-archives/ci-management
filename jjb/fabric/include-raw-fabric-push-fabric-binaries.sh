#!/bin/bash
set -o pipefail

export FABRIC_ROOT_DIR=$WORKSPACE/gopath/src/github.com/hyperledger/fabric

cd $FABRIC_ROOT_DIR

echo "=======> Build binaries for all platforms"
make release-clean release-all

BASE_VERSION=`cat Makefile | grep BASE_VERSION | awk '{print $3}' | head -1`
echo "=============> $BASE_VERSION"

COMMIT_VERSION=$(git rev-parse --short HEAD)
echo "=============> $COMMIT_VERSION"

IS_RELEASE=`cat Makefile | grep IS_RELEASE | awk '{print $3}'`
echo "=======>" $IS_RELEASE

if [ "${IS_RELEASE}" == "false" ]; then

# copy e2e_cli folder to release/$binary
     for binary in linux-amd64 windows-amd64 darwin-amd64 linux-ppc64le linux-s390x; do
       TMP=$(echo "$binary" | tr -d '-')
       mkdir -p release/$binary/chaincode/go/chaincode_example02 release/$binary/chaincode/go/marbles02
       cp $FABRIC_ROOT_DIR/examples/chaincode/go/chaincode_example02/chaincode_example02.go release/$binary/chaincode/go/chaincode_example02/
       cp $FABRIC_ROOT_DIR/examples/chaincode/go/marbles02/marbles_chaincode.go release/$binary/chaincode/go/marbles02/
       cp -ar examples/e2e_cli/. release/$binary && rm -rf release/$binary/examples && sed -i "s/e2ecli/$TMP/g" release/$binary/base/peer-base.yaml && sed -i "s/\.\./\./g" release/$binary/docker-compose-cli.yaml && tar -czf fabric-binary-$binary-$BASE_VERSION-snapshot.tar.gz release/$binary release/$binary/chaincode
       echo "Pushing fabric-binary-$binary-$BASE_VERSION-snapshot.tar.gz to maven snapshots..."
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/fabric-binary-$binary-$BASE_VERSION-snapshot.tar.gz \
        -DrepositoryId=hyperledger-snapshots \
        -Durl=https://nexus.hyperledger.org/content/repositories/snapshots/ \
        -DgroupId=org.hyperledger.fabric \
        -Dversion=$binary-$BASE_VERSION \
        -DartifactId=fabric-binary \
        -DgeneratePom=true \
        -DuniqueVersion=false \
        -Dpackaging=tar.gz \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
     done
     echo "========> DONE <======="
  else
     for binary in linux-amd64 windows-amd64 darwin-amd64 linux-ppc64le linux-s390x; do
       TMP=$(echo "$binary" | tr -d '-')
       mkdir -p release/$binary/chaincode/go/chaincode_example02 release/$binary/chaincode/go/marbles02
       cp $FABRIC_ROOT_DIR/examples/chaincode/go/chaincode_example02/chaincode_example02.go release/$binary/chaincode/go/chaincode_example02/
       cp $FABRIC_ROOT_DIR/examples/chaincode/go/marbles02/marbles_chaincode.go release/$binary/chaincode/go/marbles02/
       cp -ar examples/e2e_cli/. release/$binary && rm -rf release/$binary/examples && sed -i "s/e2ecli/$TMP/g" release/$binary/base/peer-base.yaml && sed -i "s/\.\./\./g" release/$binary/docker-compose-cli.yaml && tar -czf fabric-binary-$binary-$BASE_VERSION.tar.gz release/$binary release/$binary/chaincode
       echo "Pushing fabric-binary-$binary-$BASE_VERSION.tar.gz to maven releases..."
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/fabric-binary-$binary-$BASE_VERSION.tar.gz \
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

