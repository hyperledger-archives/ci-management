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

ARCH=$(uname -m)
echo "--------> ARCH:" $ARCH
if [ "$ARCH" != "s390x" ]; then
    # Generate Chaincode-Java API docs
    ./gradlew javadoc

    # Short Head commit
    CHAINCODE_JAVA_COMMIT=$(git rev-parse --short HEAD)
    if [ -z "$CHAINCODE_JAVA_COMMIT" ]; then
        echo "------> Failed to get java commit"
        exit 1
    else
        echo "------> CHAINCODE_JAVA_COMMIT $CHAINCODE_JAVA_COMMIT"
    fi

    # Clone CHAINCODE_JAVA API doc repository
    TARGET_REPO=$CHAINCODE_JAVA_GH_USERNAME.github.io.git
    git clone https://github.com/$CHAINCODE_JAVA_GH_USERNAME/$TARGET_REPO

    # Update API docs for the current branch
    rm -rf $CHAINCODE_JAVA_GH_USERNAME.github.io/$GERRIT_BRANCH/*
    mkdir -p $CHAINCODE_JAVA_GH_USERNAME.github.io/$GERRIT_BRANCH/api
    cp -r fabric-chaincode-shim/build/docs/javadoc/* $CHAINCODE_JAVA_GH_USERNAME.github.io/$GERRIT_BRANCH/api

    # Update any common content if this is the master branch
    if [ "$GERRIT_BRANCH" = "master" ] && [ -d docs ]; then
        find $CHAINCODE_JAVA_GH_USERNAME.github.io -maxdepth 1 ! \( -name $CHAINCODE_JAVA_GH_USERNAME.github.io -o -name '.git' -o -name 'master' -o -name 'release-*' \) -exec rm -rf {} \;
        cp -r docs/* $CHAINCODE_JAVA_GH_USERNAME.github.io
    fi

    # Commit everything and push to API doc repository
    cd $CHAINCODE_JAVA_GH_USERNAME.github.io
    git add .
    git commit -m "CHAINCODE_JAVA commit - $CHAINCODE_JAVA_COMMIT"
    git config remote.gh-pages.url https://$CHAINCODE_JAVA_GH_USERNAME:$CHAINCODE_JAVA_GH_PASSWORD@github.com/$CHAINCODE_JAVA_GH_USERNAME/$TARGET_REPO
    git push gh-pages master
fi
