#!/bin/bash
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

# Get the XML files from the daily builds.

TEST_TYPE=(behave ca pte lte ote)

for TEST_TYPE in ${TEST_TYPE[*]}; do
    curl -f -s -C - https://jenkins.hyperledger.org/view/fabric-test/job/fabric-test-daily-${TEST_TYPE}-$GERRIT_BRANCH-x86_64/lastBuild/artifact/gopath/src/github.com/hyperledger/fabric-test/regression/daily/*zip* -o ${TEST_TYPE}-daily.zip
    result=$?

    if [ $result -eq 0 ]; then
        echo "------> ${TEST_TYPE} test XML files found."
    	unzip ${TEST_TYPE}-daily.zip > /dev/null 2>&1
        # shellcheck disable=SC2046
        cp -r $(find ./daily -name "*.xml") $WORKSPACE
    	rm -rf daily  ${TEST_TYPE}-daily.zip
    else
        echo "------> ${TEST_TYPE} test XML files not found, Check ${TEST_TYPE} status."
    fi
done
