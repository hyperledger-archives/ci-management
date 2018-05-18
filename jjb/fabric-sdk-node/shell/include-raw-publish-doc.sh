#!/bin/bash -eu
set -o pipefail

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node
# Generate sdk docs
gulp doc
SDK_COMMIT=$(git rev-parse --short HEAD)
TARGET_REPO=$NODE_SDK_USERNAME.github.io.git
git clone https://github.com/$NODE_SDK_USERNAME/$TARGET_REPO

# Remove API docs to Target repository
rm -rf $NODE_SDK_USERNAME.github.io/*

# Copy API docs to Target repository
cp -r docs/gen/* $NODE_SDK_USERNAME.github.io
cd $NODE_SDK_USERNAME.github.io
git add .
git commit -m "SDK commit - $SDK_COMMIT"
git config remote.gh-pages.url https://$NODE_SDK_USERNAME:$NODE_SDK_PASSWORD@github.com/$NODE_SDK_USERNAME/$TARGET_REPO

# Push API docs to Target repository
git push gh-pages master
