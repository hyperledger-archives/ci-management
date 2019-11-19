#!/bin/bash -ue
set -o pipefail
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

checkout_project() {
    wd="$WORKSPACE/gopath/src/github.com/hyperledger/fabric-test"
    rm -rf $wd
    git clone git://cloud.hyperledger.org/mirror/fabric-test $wd
    cd $wd
    git checkout $GERRIT_BRANCH
}

run_12hr_pte_test() {
    cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-test
    # Execute Make target from fabric-test Makefile
    make svt-weekly-pte-12hr-test
}

main() {
    checkout_project
    run_12hr_pte_test
}

main
