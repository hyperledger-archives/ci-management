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
ARCH="$(dpkg --print-architecture)"
if [ "$GERRIT_BRANCH" = "master" ]; then
  export NODE_ENV_VERSION=$ARCH-2.0.0-stable
  export NODE_ENV_TAG=2.0.0

########################
# Pull nodenev image from nexus and re-tag to hyperledger/fabric-nodeenv
#######################

  docker pull nexus3.hyperledger.org:10001/hyperledger/fabric-nodeenv:$NODE_ENV_VERSION
  docker tag nexus3.hyperledger.org:10001/hyperledger/fabric-nodeenv:$NODE_ENV_VERSION hyperledger/fabric-nodeenv:amd64-$NODE_ENV_TAG
  docker tag nexus3.hyperledger.org:10001/hyperledger/fabric-nodeenv:$NODE_ENV_VERSION hyperledger/fabric-nodeenv:amd64-latest
  docker tag nexus3.hyperledger.org:10001/hyperledger/fabric-nodeenv:$NODE_ENV_VERSION hyperledger/fabric-nodeenv
##########
  docker rmi -f nexus3.hyperledger.org:10001/hyperledger/fabric-nodeenv:$NODE_ENV_VERSION
  docker images | grep hyperledger/fabric-nodeenv || true
fi
