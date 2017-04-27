#!/bin/bash

# @License EPL-1.0 <http://spdx.org/licenses/EPL-1.0>
##############################################################################
# Copyright (c) 2015 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
#
# Contributors:
#   Thanh Ha (The Linux Foundation) - Initial implementation
##############################################################################

directory=${1:-"."}

echo "Scanning $directory"
if LC_ALL=C grep -r '[^[:print:][:space:]]' "$directory"; then
    echo "Found files containing non-ascii characters."
    exit 1
fi

echo "All files are ASCII only"
