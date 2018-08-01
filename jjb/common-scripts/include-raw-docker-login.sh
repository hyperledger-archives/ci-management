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
DOCKER_REPOSITORIES="nexus3.hyperledger.org:10001 \
                   nexus3.hyperledger.org:10002 \
                   nexus3.hyperledger.org:10003"

for DOCKER_REPOSITORY in $DOCKER_REPOSITORIES;
do
    echo $DOCKER_REPOSITORY
    USER=$(xpath -e "//servers/server[id='$DOCKER_REPOSITORY']/username/text()" "$SETTINGS_FILE")
    PASS=$(xpath -e "//servers/server[id='$DOCKER_REPOSITORY']/password/text()" "$SETTINGS_FILE")

    if [ -z "$USER" ];
    then
        echo "Error: no user provided"
    fi

    if [ -z "$PASS" ];
    then
        echo "Error: no password provided"
    fi

    [ -z "$PASS" ] && PASS_PROVIDED="<empty>" || PASS_PROVIDED="<password>"
    echo docker login $DOCKER_REPOSITORY -u "$USER" -p "$PASS_PROVIDED"
    docker login $DOCKER_REPOSITORY -u "$USER" -p "$PASS"
done
