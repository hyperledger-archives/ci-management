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

directory=${1:-"."}

echo "Scanning $directory"
if LC_ALL=C grep -r '[^[:print:][:space:]]' "$directory"; then
    echo "Found files containing non-ascii characters."
    exit 1
fi

echo "All files are ASCII only"
