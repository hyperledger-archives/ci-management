#!/bin/bash -eu
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

echo "----> include-raw-fabric-sdk-java-1.4-test.sh"

wd=$WORKSPACE
cd $wd
echo "MVN= $MVN"
WD=$WORKSPACE \
  GOPATH=$wd/src/test/fixture \
  PATH=$(dirname "$MVN"):$PATH \
  ORG_HYPERLEDGER_FABRIC_SDKTEST_VERSION=1.4 \
  src/test/cirun.sh
