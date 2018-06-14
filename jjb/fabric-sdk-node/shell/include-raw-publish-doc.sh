#!/bin/bash -e
set -o pipefail

ARCH=$(uname -m)
echo "--------> ARCH:" $ARCH
if [ "$ARCH" != "s390x" ]; then
    cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node
    # Generate SDK-Node API docs
    gulp doc
    # Short Head commit
    SDK_COMMIT=$(git rev-parse --short HEAD)
    TARGET_REPO=$NODE_SDK_USERNAME.github.io.git
    # Clone SDK_NODE API doc repository
    git clone https://github.com/$NODE_SDK_USERNAME/$TARGET_REPO
    # Remove API docs target repository
    rm -rf $NODE_SDK_USERNAME.github.io/*
    # Copy API docs to target repository & push to gh-pages URL
    cp -r docs/gen/* $NODE_SDK_USERNAME.github.io
    cd $NODE_SDK_USERNAME.github.io
    git add .
    git commit -m "SDK commit - $SDK_COMMIT"
    git config remote.gh-pages.url https://$NODE_SDK_USERNAME:$NODE_SDK_PASSWORD@github.com/$NODE_SDK_USERNAME/$TARGET_REPO
    # Push API docs to Target repository
    git push gh-pages master
fi