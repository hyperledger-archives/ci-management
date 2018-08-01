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

# vim: sw=4 ts=4 sts=4 et :

# change to the script location dir and make sure everything is executable
cd "${0%/*}" || exit
chmod +x ./*.sh

# Determine our system type
./system_type.sh

source /tmp/system_type.sh
./ssh_settings.sh
#./"${SYSTEM_TYPE}.sh"

# Create Jenkins User and allow Jenkins to connect
./create_jenkins_user.sh

# Init has now completed
touch /tmp/init_finished
