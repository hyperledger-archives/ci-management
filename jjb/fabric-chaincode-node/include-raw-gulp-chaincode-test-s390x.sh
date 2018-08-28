#!/bin/bash -e
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
set -o pipefail

# Test fabric-chaincode-node tests
##################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples
REPO_PATH="${WORKSPACE}/gopath/src/github.com/hyperledger"
cd $REPO_PATH
git clone git://cloud.hyperledger.org/mirror/fabric-samples
cd $REPO_PATH/fabric-chaincode-node

rm -rf $NVM_DIR ~/.npm ~/.nvm
npm config delete prefix

# Install nvm to install multi node versions
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

# Install nodejs version 8.9.4
nvm install 8.9.4 || true

# Use nodejs 8.9.4 version
nvm use --delete-prefix v8.9.4 --silent
echo "npm version ===>"
npm -v
echo "Node version ====>"
node -v
npm install
npm config set prefix ~/npm && npm install -g gulp

echo "###############"
echo "Run Unit-tests"
echo "###############"

gulp test-headless

echo "##############"
echo "Setup Integration Environment"
echo "##############"

DEVMODE=false gulp channel-init

echo "##############"
echo "Run Integration & Scenario Tests"
echo "##############"

gulp test-e2e

# copy debug log file to $WORKSPACE directory

if [ $? == 0 ]; then
   # Copy Debug log to $WORKSPACE
   cp /tmp/fabric-shim/logs/*.log $WORKSPACE
else
   # Copy Debug log to $WORKSPACE
   cp /tmp/fabric-shim/logs/*.log $WORKSPACE
exit 1

fi
