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

REPO_PATH="${WORKSPACE}/gopath/src/github.com/hyperledger"
cd $REPO_PATH
git clone git://cloud.hyperledger.org/mirror/fabric-samples
cd $REPO_PATH/fabric-chaincode-node

# Install nvm to install multi node versions
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm

echo "------> Install NodeJS"

# Checkout to GERRIT_BRANCH
if [[ "$GERRIT_BRANCH" = *"release-1.0"* ]]; then # Only on release-1.0 branch
    NODE_VER=6.9.5
    echo "------> Use $NODE_VER for release-1.0 branch"
    nvm install $NODE_VER

    # use nodejs 8.9.4 version
    nvm use --delete-prefix v$NODE_VER --silent
elif [[ "$GERRIT_BRANCH" = *"release-1.1"* || "$GERRIT_BRANCH" = *"release-1.2"* ]]; then # only on release-1.2 or release-1.1 branches
    NODE_VER=8.9.4
    echo "------> Use $NODE_VER for release-1.1 and release-1.2 branches"
    nvm install $NODE_VER

    # use nodejs 8.9.4 version
    nvm use --delete-prefix v$NODE_VER --silent
 else
    NODE_VER=8.11.3
    echo "------> Use $NODE_VER for master"
    nvm install $NODE_VER

    # use nodejs 8.11.3 version
    nvm use --delete-prefix v$NODE_VER --silent
fi

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
