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

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node || exit

# Install nvm to install multi node versions
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

echo "------> Install NodeJS"

# Checkout to GERRIT_BRANCH
if [[ "$GERRIT_BRANCH" = *"release-1.0"* ]]; then # Only on release-1.0 branch
    NODE_VER=6.9.5
    echo "------> Use $NODE_VER for release-1.0 branch"
    nvm install $NODE_VER
    # use nodejs 6.9.5 version
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

echo "npm version ------> $(npm -v)"
echo "node version ------> $(node -v)"

npm install || err_Check "ERROR!!! npm install failed"
npm config set prefix ~/npm && npm install -g gulp
rm -rf node_modules && npm install || err_Check "ERROR!!! npm install failed"

if [ "$ARCH" != "s390x" ]; then
    # Generate SDK-Node API docs
    gulp doc
    # Short Head commit
    SDK_COMMIT=$(git rev-parse --short HEAD)
    TARGET_REPO=$NODE_SDK_USERNAME.github.io.git
    # Clone SDK_NODE API doc repository
    git clone https://github.com/$NODE_SDK_USERNAME/$TARGET_REPO
    # Copy API docs to target repository & push to gh-pages URL
    cp -r docs/gen/* $NODE_SDK_USERNAME.github.io
    cd $NODE_SDK_USERNAME.github.io
    git add .
    git commit -m "SDK commit - $SDK_COMMIT"
    git config remote.gh-pages.url https://$NODE_SDK_USERNAME:$NODE_SDK_PASSWORD@github.com/$NODE_SDK_USERNAME/$TARGET_REPO
    # Push API docs to Target repository
    git push gh-pages master
fi         
