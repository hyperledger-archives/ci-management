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

# x86_64 Specific Changes

# install npm and fabric node sdk dependencies
curl -sL https://deb.nodesource.com/setup_4.x | sudo bash -
apt-get install -y nodejs
apt-get install -y maven

npm install -g typescript
npm install -g typings
npm install -g typedoc

cd /usr/local || exit
wget https://github.com/google/protobuf/releases/download/v3.0.0/protoc-3.0.0-linux-x86_64.zip
unzip protoc-3.0.0-linux-x86_64.zip
rm protoc-3.0.0-linux-x86_64.zip
cd - || exit
