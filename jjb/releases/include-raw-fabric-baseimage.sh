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
set -o pipefail

IS_RELEASE=`cat Makefile | grep IS_RELEASE | awk '{print $3 }'`
if [ "$IS_RELEASE" == "true" ];
then
       echo "Release detected!  Triggering release promotion"
    exit 0
fi

echo "SNAPSHOT release detected, skipping release promotion"
exit -1
