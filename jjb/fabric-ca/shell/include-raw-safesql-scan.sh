#!/bin/bash
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
echo
echo "Running SafeSQL scan"
echo

export FABRIC_CA_ROOT_DIR=$WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca

cd $FABRIC_CA_ROOT_DIR || exit
go get github.com/stripe/safesql
./scripts/run_safesql_scan
