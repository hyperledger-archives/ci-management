#!/bin/bash -ex
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

    TARGET_REPO=$CHAINCODE_JAVA_GH_USERNAME.github.io.git
    git clone https://github.com/ryjones/fabric-chaincode-java.github.io.git
    cd $CHAINCODE_JAVA_GH_USERNAME.github.io
    git checkout gh-pages
    git log -1
    git remote add ghp https://$CHAINCODE_JAVA_GH_USERNAME:$CHAINCODE_JAVA_GH_PASSWORD@github.com/$CHAINCODE_JAVA_GH_USERNAME/$TARGET_REPO
    git push gh-pages ghp:master
fi
