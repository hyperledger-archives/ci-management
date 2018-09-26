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

# Clone fabric-samples.
######################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples
WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples"
REPO_NAME=fabric-samples

echo "######## Cloning fabric-samples ########"
git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
cd $WD || exit
git checkout $GERRIT_BRANCH

echo "-------> GERRIT_BRANCH: $GERRIT_BRANCH"
FABRIC_SAMPLES_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC_SAMPLES_COMMIT ========> $FABRIC_SAMPLES_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
