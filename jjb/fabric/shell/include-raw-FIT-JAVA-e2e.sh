#!/bin/bash -eu
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
echo "##################"
echo -e "\033[1m S D K - J A V A\033[0m"
echo "##################"
echo
if [[ "$GERRIT_BRANCH" != "release-1.0" && "$ARCH" != "s390x" && "$ARCH" != "ppc64le" ]]; then

    echo -e "\033[1;32m STARTING fabric-sdk-java tests on $GERRIT_BRANCH \033[0m"
    WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-java"
    rm -rf $WD
    # Clone fabric-sdk-java repository
    git clone git://cloud.hyperledger.org/mirror/fabric-sdk-java $WD
    cd $WD
    git checkout $GERRIT_BRANCH
    export GOPATH=$WD/src/test/fixture
    cd $WD/src/test
    chmod +x cirun.sh
    source cirun.sh
else
    echo -e "\033[32m TEMPORARILY SDK JAVA TESTS ARE DISABLED IN $GERRIT_BRANCH BRANCH \033[0m"
fi
