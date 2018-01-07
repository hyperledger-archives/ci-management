#!/bin/bash

# This script makes several basic commit message validations.
# This is with the purpose of keeping up with the aesthetics
# of our code.

# Verify if the commit message contains JIRA URLs.
# its-jira pluggin attempts to process jira links and breaks.

# Also, verifies if the commit message contains WIP or only .rst
# changes. If commit has .rst files changed, set NEXT_TASK to doc_build
# if WIP, set NEXT_TASK to nothing and ignore the rest of the build process
# if any other changes, set NEXT_TASK to fabric_build and trigger the
# downstream jobs (fabric-verify-unit-tests, fabric-verify-behave-tests)

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
   NEXT_TASK=nothing
   echo "NEXT_TASK=$NEXT_TASK" > $WORKSPACE/env.properties
else
   DOC=$(git diff-tree --no-commit-id --name-only -r HEAD | egrep '.md|.rst|.txt')
   echo "======> $DOC"
   echo
if [[ ! -z "$DOC" ]];
then
   echo 'Ignore this patch set as changes are related to docs'
   NEXT_TASK=doc_build
   echo "NEXT_TASK=$NEXT_TASK" > $WORKSPACE/env.properties
else
   NEXT_TASK=fabric_build
   echo "NEXT_TASK=$NEXT_TASK" > $WORKSPACE/env.properties

# Build docker images and perform build process

time make basic-checks docker

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

NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"

dockerTag() {
  for IMAGES in peer orderer ccenv javaenv tools; do
    echo "==> $IMAGES"
    echo
    docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT
    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$GIT_COMMIT"
  done
}

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

echo
echo "Publish fabric binaries"
echo
binary=linux-amd64
time make release-clean dist-clean dist

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
fi
fi
