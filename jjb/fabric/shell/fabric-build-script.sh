#!/bin/bash -x
#
# SPDX-License-Identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 IBM Corporation, The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License 2.0
# which accompanies this distribution, and is available at
# https://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# This script makes several basic commit message validations.
# This is with the purpose of keeping up with the aesthetics
# of our code.

# Verify if the commit message contains JIRA URLs.
# its-jira pluggin attempts to process jira links and breaks.

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric || exit

vote() {
    [[ -z ${GERRIT_HOST:-} ]] && return
    ssh -p 29418 hyperledger-jobbuilder@$GERRIT_HOST gerrit review \
        $GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER \
        --notify '"NONE"' "$@"
}

vote -m '"Starting verify build"' -l F1-VerifyBuild=0 -l F3-UnitTest=0 -l F3-IntegrationTest=0 -l F2-DocBuild=0

JIRA_LINK=`git rev-list --format=%B --max-count=1 HEAD | grep -io 'http[s]*://jira\..*'`
if [[ ! -z "$JIRA_LINK" ]]
then
  echo 'Error: Remove JIRA URLs from commit message'
  echo 'Add jira references as: Issue: <JIRAKEY>-<ISSUE#>, instead of URLs'
  vote -m '"Remove JIRA URLs from commit message"' -l F1-VerifyBuild=-1
  exit 1
fi

codeChange() {
             CHECKS_CMD="make basic-checks native"
             if [[ "$GERRIT_BRANCH" = "release-1.0" ]]; then # release-1.0 branch
                 echo "------> make linter"
                 CHECKS_CMD="make linter"
             fi
                 echo "------> $CHECKS_CMD"
                 $CHECKS_CMD
                    if [ $? != 0 ]; then
                         echo "------> $CHECKS_CMD FAILED"
                         vote -m '"code checks are failed"' -l F1-VerifyBuild=-1
                         exit 1
                    fi
}

WIP=`git rev-list --format=%B --max-count=1 HEAD | grep -io 'WIP'`
echo
if [[ ! -z "$WIP" ]];then
    echo -e "\033[1m-------> Ignore WIP Build\033[0m"
    vote -m '"WIP - No Build"' -l F1-VerifyBuild=0
else
    doc_change=$(git diff-tree --no-commit-id --name-only -r HEAD | egrep '.md$|.rst$|.txt$|conf.py$|.png$|.pptx$|.css$|.html$|.ini$')
    echo -e "------> DOC_CHANGE = $doc_change"
    code_change=$(git diff-tree --no-commit-id --name-only -r HEAD | egrep -v '.md$|.rst$|.txt$|conf.py$|.png$|.pptx$|.css$|.html$|.ini$')
    echo "------> CODE_CHANGE = $code_change"
    if [ ! -z "$doc_change" ] && [ -z "$code_change" ]; then # only doc change
          echo "------> Only Doc change, trigger documentation build"
          vote -m '"Succeeded, Run DocBuild"' -l F1-VerifyBuild=+1 -l F3-UnitTest=+1 -l F3-IntegrationTest=+1
     elif [ ! -z "$doc_change" ] && [ ! -z "$code_change" ]; then # Code and Doc change
          echo -e "\033[1m------> Code and Doc change\033[0m"
          codeChange
          vote -m '"Succeeded, Run DocBuild, Run UnitTest, Run IntegrationTest"' -l F1-VerifyBuild=+1
     else  # only code change
          echo "------> Only code change, trigger Unit and Integration Tests"
          codeChange
          vote -m '"Succeeded, Run IntegrationTest, Run UnitTest"' -l F1-VerifyBuild=+1 -l F2-DocBuild=+1
     fi
fi
