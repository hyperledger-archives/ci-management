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

echo "----> include-raw-fabric-sdk-java-end-to-end-tests.sh"

# This script clones the Hyperledger fabric repository,
# the fabric-ca repository, and runs the end-to-end tests
# with fabric-sdk-java.
set -e -o pipefail

# Clone fabric git repository
#############################
clone_fabric()
{
    echo "${FUNCNAME[0]}()"

    local repo_name=fabric
    local wd="$WORKSPACE/gopath/src/github.com/hyperledger/$repo_name"
    rm -rf "$wd"
    git clone "git://cloud.hyperledger.org/mirror/$repo_name" "$wd"

    cd "$wd"
    if [[ $FABRIC_COMMIT == latest ]]; then
        echo "Fabric commit is $FABRIC_COMMIT so go with this"
    else
        git checkout "$FABRIC_COMMIT"
    fi

    fabric_commit_level=$(git log -1 --pretty=format:"%h")

    # Build fabric Docker images
    local go_ver
    go_ver=$(grep GO_VER ci.properties | cut -d "=" -f 2)
    export GOROOT=/opt/go/go$go_ver.linux.amd64
    local save_path=$PATH
    if [[ -d $GOROOT/bin ]]; then
        export PATH=$GOROOT/bin:$save_path
    else
        echo "ERROR: GO ($go_ver) is not available"
        exit 1
    fi
    type go
    echo "make docker-fabric-ca"
    make docker docker-thirdparty
    docker images | grep hyperledger
    PATH=$save_path
    unset GOROOT
}

# Clone fabric-ca git repository
################################
clone_fabric_ca()
{
    echo "${FUNCNAME[0]}()"

    local repo_name=fabric-ca
    local wd="$WORKSPACE/gopath/src/github.com/hyperledger/$repo_name"
    rm -rf "$wd"
    git clone "git://cloud.hyperledger.org/mirror/$repo_name" "$wd"

    cd "$wd"
    if [[ $FABRIC_CA_COMMIT == latest ]]; then
        echo "Fabric_CA commit is $FABRIC_COMMIT so go with this"
    else
        git checkout "$FABRIC_CA_COMMIT"
    fi

    ca_commit_level=$(git log -1 --pretty=format:"%h")

    # Build CA Docker Images
    local go_ver
    go_ver=$(grep GO_VER ci.properties | cut -d "=" -f 2)
    export GOROOT=/opt/go/go$go_ver.linux.amd64
    local save_path=$PATH
    if [[ -d $GOROOT/bin ]]; then
        export PATH=$GOROOT/bin:$PATH
    else
        echo "ERROR: GO ($go_ver) is not available"
        exit 1
    fi
    type go
    echo "make docker-fabric-ca"
    make docker-fabric-ca
    docker images | grep hyperledger
    PATH=$save_path
    unset GOROOT
}

# Run end-to-end Java SDK tests
################################
run_e2e_tests()
{
    local wd=$WORKSPACE
    cd $wd
    java_sdk_commit_level=$(git log -1 --pretty=format:"%h")

    echo "=======> FABRIC COMMIT NUMBER - $fabric_commit_level =======>" \
       "FABRIC CA COMMIT NUMBER - $ca_commit_level =======>"           \
       "FABRIC SDK JAVA COMMIT NUMBER - $java_sdk_commit_level"        \
       >> commit_history.log

    echo "MVN  == $MVN"
    # Add MVN to path and execute cirun.sh
    WD=$WORKSPACE \
      GOPATH=$wd/src/test/fixture \
      PATH=$(dirname "$MVN"):$PATH \
      src/test/cirun.sh
}

main()
{
    # Skip build when the value is true
    if [[ -z ${FABRIC_NO_BUILD:-} ]]; then
        clone_fabric
    fi
    # Skip build when the value is true
    if [[ -z ${FABRIC_CA_NO_BUILD:-} ]]; then
        clone_fabric_ca
    fi
    run_e2e_tests
}

##########  End of Function Definitions  ##########

if [[ $GERRIT_BRANCH == master ]]; then
   export NODE_ENV_VERSION=amd64-2.0.0-stable
   export NODE_ENV_TAG=2.0.0

   ########################
   # Pull nodenev image from nexus and re-tag to hyperledger/fabric-nodeenv
   #######################

   docker pull nexus3.hyperledger.org:10001/hyperledger/fabric-nodeenv:$NODE_ENV_VERSION
   docker tag nexus3.hyperledger.org:10001/hyperledger/fabric-nodeenv:$NODE_ENV_VERSION hyperledger/fabric-nodeenv:amd64-$NODE_ENV_TAG
   docker tag nexus3.hyperledger.org:10001/hyperledger/fabric-nodeenv:$NODE_ENV_VERSION hyperledger/fabric-nodeenv:amd64-latest
   docker tag nexus3.hyperledger.org:10001/hyperledger/fabric-nodeenv:$NODE_ENV_VERSION hyperledger/fabric-nodeenv
   ##########
   docker images | grep hyperledger/fabric-nodeenv || true
fi

# shellcheck source=/dev/null
source $WORKSPACE/src/test/fabric_test_commitlevel.sh

main
