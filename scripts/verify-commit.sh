#!/bin/bash -ue

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
# This is with the purpose of keeping up with the aesthetics of our code.
# Verify if the commit message contains JIRA URLs.
# its-jira pluggin attempts to process jira links and breaks.

set -o pipefail
echo "----> verify-commit.sh"

echo "########  DEBUG  ########"
echo "WORKSPACE = $WORKSPACE"
echo "BASE_DIR  = $BASE_DIR"
echo "PROJECT   = $PROJECT"
echo "########  DEBUG  ########"

# Until project names are added to the switch statement below
exit 0

case $PROJECT in
    project1|project2|project3) ;;&
    fabric-sdk-py)
        cd $WORKSPACE/$BASE_DIR ;;
    project100|project101|project102) ;;&
    project200|project201|project202) ;;&
    ci-management*)
        cd $WORKSPACE ;;
    *) echo "FATAL: Unknown Project" ; exit -1;;
esac

# Exit with error if we are not inside a repo
git rev-parse --is-inside-git-dir > /dev/null

# Check for JIRA URL's in the Commit Message
if git rev-list --format=%B --max-count=1 HEAD | grep -io 'http[s]*://jira\..*' > /dev/null ; then
    echo 'Error: Remove JIRA URLs from commit message'
    echo 'Add jira references as: Issue: <JIRAKEY>-<ISSUE#>, instead of URLs'
    exit 1
fi

# Check for trailing white-space (tab or spaces) in any files that were changed
echo "Checking for trailing white-space..."
commit_files=$(git diff-tree --name-only -r HEAD~1..HEAD)
found_trailing=false
for filename in $commit_files; do
    if [[ $(file -b $filename) == "ASCII text"* ]]; then
        if egrep -q "\s$" $filename; then
            found_trailing=true
            ascii_file_list+="$filename "
            echo "Error: Trailing white spaces found in file: $filename"
        fi
    fi
done

if $found_trailing; then
    echo "####  filename:line-num:line  ####"
    egrep -Hn "\s$" $ascii_file_list
    exit 1
fi
