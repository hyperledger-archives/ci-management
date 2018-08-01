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

# Remove fabric-test repository
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test"
FABRIC_TEST_REPO_NAME=fabric-test
git clone git://cloud.hyperledger.org/mirror/$FABRIC_TEST_REPO_NAME $WD

echo "=========> Install govendor"
go get -u github.com/kardianos/govendor

cd $WD || exit

FABRIC_TEST_COMMIT=$(git log -1 --pretty=format:"%h")
echo "FABRIC TEST COMMIT ========> $FABRIC_TEST_COMMIT"
echo
echo "FABRIC TEST COMMIT ========> $FABRIC_TEST_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log

# update submodules
git submodule update --init --recursive

echo "========== Behave feature and system tests..."
echo
cd regression/smoke && ./runSmokeTestSuite.sh
