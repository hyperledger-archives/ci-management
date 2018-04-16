#!/bin/bash -x

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

vote(){
     ssh -p 29418 hyperledger-jobbuilder@$GERRIT_HOST gerrit review \
          $GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER \
          --notify '"NONE"' \
          "$@"
}

vote -m '"Starting verify build"' -l F1-VerifyBuild=0 -l F2-SmokeTest=0 -l F3-UnitTest=0 -l F2-DocBuild=0

JIRA_LINK=`git rev-list --format=%B --max-count=1 HEAD | grep -io 'http[s]*://jira\..*'`
if [[ ! -z "$JIRA_LINK" ]]
then
  echo 'Error: Remove JIRA URLs from commit message'
  echo 'Add jira references as: Issue: <JIRAKEY>-<ISSUE#>, instead of URLs'
  vote -m '"Remove JIRA URLs from commit message"' -l F1-VerifyBuild=-1
  exit 1
fi

# Verify if there are trailing spaces in the files.

COMMIT_FILES=`git diff-tree --no-commit-id --name-only -r HEAD | grep -Ev '(^|/)vendor/'`

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
  vote -m '"Trailing white spaces found"' -l F1-VerifyBuild=-1
  exit 1
fi

codeChange() {
             CHECKS_CMD="make basic-checks"
             if [[ "$GERRIT_BRANCH" = "release-1.0" ]]; then # release-1.0 branch
                 echo "------> make linter"
                 CHECKS_CMD="make linter"
             fi
                 echo "------> $CHECKS_CMD"
                 $CHECKS_CMD
                    if [ $? = 0 ]; then
                         echo
                         echo "------> Build docker images"
                    else
                         echo "------> $CHECKS_CMD FAILED"
                         vote -m '"$CHECKS_CMD are failed"' -l F1-VerifyBuild=-1
                         exit 1
                    fi
             make docker
                    if [ $? = 0 ]; then
                         ORG_NAME=hyperledger/fabric
                         NEXUS_URL=nexus3.hyperledger.org:10003
                         ORG_NAME="hyperledger/fabric"
                         TAG=$GIT_COMMIT
                         export COMMIT_TAG=${TAG:0:7}

                         dockerTag() {
                               for IMAGES in peer orderer ccenv tools; do
                                    echo "==> $IMAGES"
                                    echo
                                    docker tag $ORG_NAME-$IMAGES $NEXUS_URL/$ORG_NAME-$IMAGES:$COMMIT_TAG
                                    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$COMMIT_TAG"
                               done
                               }

                          dockerFabricPush() {
                               for IMAGES in peer orderer ccenv tools; do
                                    echo "==> $IMAGES"
                                    docker push $NEXUS_URL/$ORG_NAME-$IMAGES:$COMMIT_TAG
                                    echo
                                    echo "==> $NEXUS_URL/$ORG_NAME-$IMAGES:$COMMIT_TAG"
                               done
                               }

                          # Tag Fabric Docker Images to Nexus Repository
                          dockerTag
                          # Push Fabric Docker Images to Nexus Repository
                          dockerFabricPush
                          # Listout all docker images Before and After Push to NEXUS
                          docker images | grep "nexus*"
                     else
                          echo "-------> make docker failed"
                          vote -m '"make docker failed"' -l F1-VerifyBuild=-1
                          exit 1
                    fi
               binary=linux-amd64
               make release-clean dist-clean
               make dist
                    if [ $? = 0 ]; then
                                     # Push fabric-binaries to nexus2
                                     cd release/$binary && tar -czf hyperledger-fabric-$binary.$COMMIT_TAG.tar.gz *
                                     cd $FABRIC_ROOT_DIR || exit
                                     echo "Pushing hyperledger-fabric-$binary.$COMMIT_TAG.tar.gz to maven.."
                                     mvn -B org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
                                     -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/$binary/hyperledger-fabric-$binary.$COMMIT_TAG.tar.gz \
                                     -DrepositoryId=hyperledger-releases \
                                     -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
                                     -DgroupId=org.hyperledger.fabric \
                                     -Dversion=$binary-$COMMIT_TAG \
                                     -DartifactId=hyperledger-fabric-build \
                                     -DgeneratePom=true \
                                     -DuniqueVersion=false \
                                     -Dpackaging=tar.gz \
                                     -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
                                     echo "-------> DONE <----------"
                    else
                                     echo "-------> make dist failed"
                                     vote -m '"make dist failed"' -l F1-VerifyBuild=-1
                                     exit 1
                    fi
}

WIP=`git rev-list --format=%B --max-count=1 HEAD | grep -io 'WIP'`
echo
if [[ ! -z "$WIP" ]];then
    echo '-------> Ignore WIP Build'
    vote -m '"WIP - No Build"' -l F1-VerifyBuild=0
else
    DOC_CHANGE=$(git diff-tree --no-commit-id --name-only -r HEAD | egrep '.md|.rst|.txt|conf.py|.png|.pptx|.css|.html|.ini')
    echo "------> DOC_CHANGE = $DOC_CHANGE"
    CODE_CHANGE=$(git diff-tree --no-commit-id --name-only -r HEAD | egrep -v '.md|.rst|.txt|conf.py|.png|.pptx|.css|.html|.ini')
    echo "------> CODE_CHANGE = $CODE_CHANGE"
           if [ ! -z "$DOC_CHANGE" ] && [ -z "$CODE_CHANGE" ]; then # only doc change
                  echo "------> Only Doc change, trigger documentation build"
                  vote -m '"Succeeded, Run DocBuild"' -l F1-VerifyBuild=+1 -l F2-SmokeTest=+1 -l F3-UnitTest=+1
           elif [ ! -z "$DOC_CHANGE" ] && [ ! -z "$CODE_CHANGE" ]; then # Code and Doc change
                    echo "------> Code and Doc change, trigger just doc and smoketest build jobs"
                    codeChange
                    vote -m '"Succeeded, Run DocBuild, Run SmokeTest"' -l F1-VerifyBuild=+1
               else  # only code change
                    echo "------> Only code change, trigger smoketest build job"
                    codeChange
                    vote -m '"Succeeded, Run SmokeTest"' -l F1-VerifyBuild=+1 -l F2-DocBuild=+1
           fi
fi
