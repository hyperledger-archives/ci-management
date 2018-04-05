#!/bin/bash -x

# RUN END-to-END Tests
######################
set +e

vote(){
     ssh -p 29418 hyperledger-jobbuilder@$GERRIT_HOST gerrit review \
          $GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER \
          --notify '"NONE"' \
          "$@"
}

post_Result() {
   if [ $1 != 0 ]; then
         vote -m '"Failed"' -l F2-SmokeTest=-1
         exit 1
   fi
}

vote -m '"Starting smoke tests"' -l F2-SmokeTest=0 -l F3-UnitTest=0

NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"
MARCH=$(uname -m)
TAG=$GIT_COMMIT
export CCENV_TAG=${TAG:0:7}
cd ${GOPATH}/src/github.com/hyperledger/fabric
VERSION=$(make -f Makefile -f <(printf 'p:\n\t@echo $(BASE_VERSION)\n') p)
echo "------> BASE_VERSION = $VERSION"

dockerTag() {
  for IMAGES in peer orderer ccenv tools; do
    echo "==> $IMAGES"
    echo
    docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$CCENV_TAG
    post_Result $?
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$CCENV_TAG $ORG_NAME-$IMAGES
    post_Result $?
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$CCENV_TAG"
  done
}

# Tag Fabric Nexus docker images to hyperledger
dockerTag
docker tag $NEXUS_URL/$ORG_NAME-ccenv:$CCENV_TAG $ORG_NAME-ccenv:$MARCH-$VERSION-snapshot-$CCENV_TAG

# List all hyperledger docker images
docker images | grep "hyperledger*"

WD="${GOPATH}/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples
rm -rf $WD

git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$REPO_NAME $WD
cd $WD || exit
git checkout $GERRIT_BRANCH
FABRIC_SAMPLES_COMMIT=$(git log -1 --pretty=format:"%h")
echo "-------> FABRIC_SAMPLES_COMMIT = $FABRIC_SAMPLES_COMMIT"
curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-build/linux-amd64-$CCENV_TAG/hyperledger-fabric-build-linux-amd64-$CCENV_TAG.tar.gz | tar xz

cd first-network
export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

byfn_Result() {
   if [ $1 = 0 ]; then
         vote -m '"Succeeded, Run UnitTest"' -l F2-SmokeTest=+1
   else
         vote -m '"Failed"' -l F2-SmokeTest=-1
         exit 1
   fi
}
# Execute below tests
echo
echo "======> DEFAULT CHANNEL <======"

echo y | ./byfn.sh -m down
post_Result $?
echo y | ./byfn.sh -m generate
post_Result $?
echo y | ./byfn.sh -m up -t 10
post_Result $?
echo y | ./byfn.sh -m down
post_Result $?

echo
echo "======> CUSTOM CHANNEL <======="

echo y | ./byfn.sh -m generate -c fabricrelease
post_Result $?
echo y | ./byfn.sh -m up -c fabricrelease -t 10
post_Result $?
echo y | ./byfn.sh -m down
post_Result $?


echo
echo "======> CouchDB tests <======="

echo y | ./byfn.sh -m generate -c couchdbtest
post_Result $?
echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 10
post_Result $?
echo y | ./byfn.sh -m down
byfn_Result $?
set -e
