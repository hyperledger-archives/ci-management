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

# Run end-to-end (CLI) Tests
############################

if [[ "$GERRIT_BRANCH" == "release-1.0" || "$GERRIT_BRANCH" == "release-1.1" ]]; then
    echo "----------> SKIP e2e_cli tests FAB-11077"
else
    cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/examples/e2e_cli
    # wait for 10 sec's before exit
    ./network_setup.sh restart mychannel 10
    docker ps -a &&  docker logs -f cli | tee results.log && ./network_setup.sh down
    grep -q "All GOOD, End-2-End execution completed " results.log
    if [[ $? -ne 0 ]]; then
        echo "=============E2E TEST FAILED========="
        exit 1
    else
        echo "=============E2E TEST PASSED=========="
    fi
fi
