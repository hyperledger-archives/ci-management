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

    TARGET_REPO=$CHAINCODE_JAVA_GH_USERNAME.github.io.git
    # Clone CHAINCODE_JAVA API doc repository
    git clone https://github.com/$CHAINCODE_JAVA_GH_USERNAME/$TARGET_REPO
    # Remove API docs target repository
    rm -rf $CHAINCODE_JAVA_GH_USERNAME.github.io/*
    # Copy API docs to target repository & push to gh-pages URL
    cp -r fabric-chaincode-shim/build/docs/javadoc/* $CHAINCODE_JAVA_GH_USERNAME.github.io
    cd $CHAINCODE_JAVA_GH_USERNAME.github.io
    git add .
    git commit -m "CHAINCODE_JAVA commit - $CHAINCODE_JAVA_COMMIT"
    git config remote.gh-pages.url https://$CHAINCODE_JAVA_GH_USERNAME:$CHAINCODE_JAVA_GH_PASSWORD@github.com/$CHAINCODE_JAVA_GH_USERNAME/$TARGET_REPO
    # Push API docs to Target repository
    git push gh-pages master
fi
