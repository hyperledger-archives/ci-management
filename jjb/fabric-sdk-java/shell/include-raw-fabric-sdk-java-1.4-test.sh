#!/bin/bash -exu
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

export WD=${WORKSPACE}
export GOPATH=$WD/src/test/fixture
cd $GOPATH
export ORG_HYPERLEDGER_FABRIC_SDKTEST_VERSION="1.4"
cd $WD/src/test
chmod +x cirun.sh
source cirun.sh
