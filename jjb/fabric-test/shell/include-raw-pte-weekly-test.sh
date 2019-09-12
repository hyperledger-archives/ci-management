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
    # Fetch Go Version from fabric ci.properties file
    curl -L https://raw.githubusercontent.com/hyperledger/fabric/$GERRIT_BRANCH/ci.properties > ci.properties
    GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
    eval "$(grep GO_VER ci.properties)"
        if [ -z "$GO_VER" ]; then
            echo "-----> Empty GO_VER"
            exit 1
        fi
    echo "GO_VER="$GO_VER
    export GO_VER
    OS_VER=$(dpkg --print-architecture)
    echo "------> ARCH: $OS_VER"
    export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
    export PATH=$GOROOT/bin:$PATH
    echo "------> GO_VER" $GO_VER
    # Execute Make target from fabric-test Makefile
    make svt-weekly-pte-12hr-test
}

main() {
    checkout_project
    run_12hr_pte_test
}

main
