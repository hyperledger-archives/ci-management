#!/bin/bash
set -o pipefail

# Build fabric images
cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric || exit

make docker
if [ $? != 0 ]; then
     echo "--------> make docker failed"
     exit 1
fi

# Listout all docker images
docker images

# Publish fabric docker images
NEXUS_URL=nexus3.hyperledger.org:10002
ARCH=$(dpkg --print-architecture)
VERSION=$(cat Makefile | grep "BASE_VERSION =" | awk '{print $3}')

if [ $ARCH = s390x ]; then
   echo "--------> $ARCH"
   ARCH=s390x
elif [[ "$GERRIT_BRANCH" = *"release-1.1"* ]]; then
   ARCH=x86_64
   echo "----------> ARCH:" $ARCH
else
   ARCH=amd64
   echo "----------> ARCH:" $ARCH
fi

for IMAGES in peer orderer tools ccenv; do
      docker tag hyperledger/fabric-$IMAGES:$ARCH-$VERSION $NEXUS_URL/hyperledger/fabric-$IMAGES:$ARCH-$VERSION
      docker push $NEXUS_URL/hyperledger/fabric-$IMAGES:$ARCH-$VERSION
      echo "--------> Push fabric Image version:" $NEXUS_URL/hyperledger/fabric-$IMAGES:$ARCH-$VERSION
done
