#!/bin/bash -exu
set -o pipefail

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-test
make git-init && make git-latest || exit 1
GO_VER=`cat fabric/ci.properties | grep GO_VER | cut -d "=" -f 2`
OS_VER=$(dpkg --print-architecture)
echo "------> ARCH: $OS_VER"
export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
export PATH=$GOROOT/bin:$PATH
echo "----> GO_VER" $GO_VER
echo "=========> Install govendor"
go get -u github.com/kardianos/govendor
make pre-setup || exit 1

echo "Fetching images from Nexus"
NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"
MARCH=$(go env GOARCH)
cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-test/fabric
# Fetch the published stable binary from nexus
MVN_METADATA=$(echo "https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-stable/maven-metadata.xml")
curl -L "$MVN_METADATA" > maven-metadata.xml
RELEASE_TAG=$(cat maven-metadata.xml | grep release)
COMMIT=$(echo $RELEASE_TAG | awk -F - '{ print $4 }' | cut -d "<" -f1)
VERSION=$(cat Makefile | grep "BASE_VERSION =" | cut -d "=" -f2 | cut -d " " -f2)
echo "------> BASE_VERSION = $VERSION"

dockerTag() {
  for IMAGES in peer orderer ccenv tools ca; do
    echo "==> $IMAGES"
    echo
    docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:stable
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:stable $ORG_NAME-$IMAGES
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:stable"
  done
}

# Pull and Tag Fabric Nexus docker images to hyperledger
dockerTag
docker tag $NEXUS_URL/$ORG_NAME-ccenv:stable $ORG_NAME-ccenv:$MARCH-$VERSION-snapshot-$COMMIT

# List all hyperledger docker images and binaries.
echo "-------> Images fetched from Nexus <--------"
docker images | grep "hyperledger*"
echo
rm -rf .build && mkdir -p .build && cd .build
curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-stable/linux-amd64-stable-$COMMIT/hyperledger-fabric-stable-linux-amd64-stable-$COMMIT.tar.gz | tar xz
export PATH=$WORKSPACE/gopath/src/github.com/hyperledger/fabric-test/fabric/.build/bin/:$PATH
echo
cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-test
echo "=======> Run Daily test suite..."
make daily-tests || exit 1
