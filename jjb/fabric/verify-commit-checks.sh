#!/bin/bash

# This script makes several basic commit message validations.
# This is with the purpose of keeping up with the aesthetics
# of our code.

# Verify if the commit message contains JIRA URLs.
# its-jira pluggin attempts to process jira links and breaks.

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric || exit

JIRA_LINK=`git rev-list --format=%B --max-count=1 HEAD | grep -io 'http[s]*://jira\..*'`
if [[ ! -z "$JIRA_LINK" ]]
then
  echo 'Error: Remove JIRA URLs from commit message'
  echo 'Add jira references as: Issue: <JIRAKEY>-<ISSUE#>, instead of URLs'
  exit 1
fi

# Verify if there are trailing spaces in the files.

COMMIT_FILES=`git diff-tree --name-only -r HEAD~1..HEAD`

for filename in `echo $COMMIT_FILES`; do
  if [[ `file $filename` == *"ASCII text"* ]];
  then
    if [ ! -z "`egrep -l " +$" $filename`" ];
    then
      FOUND_TRAILING='yes'
      echo "Error: Trailing white spaces found in file:$filename"
    fi
  fi
done

if [ ! -z ${FOUND_TRAILING+x} ];
then
  exit 1
fi

WIP=`git rev-list --format=%B --max-count=1 HEAD | grep -io 'WIP'`
echo "======> $WIP"
echo

if [[ ! -z "$WIP" ]];
then
  echo 'Ignore this patch set as this is a WIP'
  echo 'Ignore this Build'
  exit 1
fi

DOC=$(git diff-tree --no-commit-id --name-only -r HEAD | egrep '.md|.rst|.txt')
echo "======> $DOC"
echo

if [[ ! -z "$DOC" ]];
then
   echo 'Ignore this patch set as changes are related to docs'
   echo 'Ignore This Build'
   exit 1
fi

# BUILD DOCKER IMAGES && BINARIES

make docker -C $WORKSPACE/gopath/src/github.com/hyperledger/fabric || exit

ORG_NAME=hyperledger/fabric
dockerFabricCheck() {

# shellcheck disable=SC2043
docker images
  for IMAGES in peer orderer ccenv javaenv tools; do
    echo "=======> $IMAGES"
    docker images $ORG_NAME-$IMAGES
    echo "Images are available"
    echo "=======> $ORG_NAME-$IMAGES"
    echo
done
}
dockerFabricCheck

# PUSH DOCKER IMAGES

NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"
# tag fabric images to nexusrepo

dockerTag() {
  for IMAGES in peer ordere ccenv javaenv tools; do
    echo "==> $IMAGES"
    echo
    docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT"
  done
}
# Push docker images to nexus repository

dockerFabricPush() {
  for IMAGES in peer orderer ccenv javaenv tools; do
    echo "==> $IMAGES"
    docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT
    echo
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT"
  done
}

# Tag Fabric Docker Images to Nexus Repository
dockerTag

# Push Fabric Docker Images to Nexus Repository
dockerFabricPush

# Listout all docker images Before and After Push to NEXUS
docker images | grep "nexus*"
