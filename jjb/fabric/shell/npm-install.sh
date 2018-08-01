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

# Installs NodeJS using NVM from GitHub.
#
# Parameters:
#     NODE_VERSION: (default: 8.9.4)
#     NVM_VERSION: (default: 0.33.2)

NODE_VERSION="${NODE_VERSION:-8.9.4}"
NVM_VERSION="${NVM_VERSION:-0.33.2}"

# Ensure we fail the job if any steps fail.
set -e -o pipefail

wget -qO- https://raw.githubusercontent.com/creationix/nvm/v${NVM_VERSION}/install.sh | bash
# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"

nvm install "$NODE_VERSION" || true
nvm use --delete-prefix "v$NODE_VERSION" --silent

echo "============================================================"
echo "npm version: $(npm -v)"
echo "node version: $(node -v)"
echo "============================================================"
