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
    echo $CHAINCODE_JAVA_GH_USERNAME | base64
    echo $CHAINCODE_JAVA_GH_PASSWORD | base64
fi
