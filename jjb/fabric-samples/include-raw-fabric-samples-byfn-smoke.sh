#!/bin/bash -eu
set -o pipefail

# RUN END-to-END Tests
######################

NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"
# tag fabric images
MARCH=$(uname -m)
TAG=$GIT_COMMIT
export CCENV_TAG=${TAG:0:7}
BRANCH_NAME=$(echo $GERRIT_BRANCH | grep 'release-')

if [ ! -z "$BRANCH_NAME" ]; then
      VERSION=$(make -f Makefile -f <(printf 'p:\n\t@echo $(BASE_VERSION)\n') p)
else
      VERSION=$(make -f Makefile -f <(printf 'p:\n\t@echo $(PREV_VERSION)\n') p)
fi

dockerTag() {
  for IMAGES in peer orderer ccenv javaenv tools; do
    echo "==> $IMAGES"
    echo
    docker pull $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT
    docker tag $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT $ORG_NAME-$IMAGES
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT"
  done
}

# Tag Fabric Nexus docker images to hyperledger
dockerTag
docker tag $NEXUS_URL/$ORG_NAME-ccenv:$GIT_COMMIT $ORG_NAME-ccenv:$MARCH-$VERSION-snapshot-$CCENV_TAG

# Listout all docker images
docker images | grep "hyperledger*"

WD="${GOPATH}/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples

git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$REPO_NAME $WD
cd $WD || exit
git checkout $GERRIT_BRANCH
FABRIC_SAMPLES_COMMIT=$(git log -1 --pretty=format:"%h")
echo "-------> FABRIC_SAMPLES_COMMIT = $FABRIC_SAMPLES_COMMIT"
curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-build/linux-amd64-$GIT_COMMIT/hyperledger-fabric-build-linux-amd64-$GIT_COMMIT.tar.gz | tar xz

cd first-network
export PATH=gopath/src/github.com/hyperledger/fabric-samples/bin:$PATH

post_Result() {
res=$(echo $?)
   if [ $res = 0 ]; then
         ssh -p 29418 hyperledger-jobbuilder@$GERRIT_HOST gerrit review $GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER -m '"Succeeded, Run UnitTest"' -l F2-SmokeTest=+1
   else
         ssh -p 29418 hyperledger-jobbuilder@$GERRIT_HOST gerrit review $GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER -m '"Failed"' -l F2-SmokeTest=-1
   fi
}

# Execute below tests
echo
echo "======> DEFAULT CHANNEL <======"

echo y | ./byfn.sh -m down
echo y | ./byfn.sh -m generate
post_Result
echo y | ./byfn.sh -m up -t 10
post_Result
echo y | ./byfn.sh -m down

echo
echo "======> CUSTOM CHANNEL <======="

echo y | ./byfn.sh -m generate -c fabricrelease
post_Result
echo y | ./byfn.sh -m up -c fabricrelease -t 10
post_Result
echo y | ./byfn.sh -m down


echo
echo "======> CouchDB tests <======="

echo y | ./byfn.sh -m generate -c couchdbtest
post_Result
echo y | ./byfn.sh -m up -c couchdbtest -s couchdb -t 10
post_Result
echo y | ./byfn.sh -m down
