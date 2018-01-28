#!/bin/bash

# Installs NodeJS using NVM from GitHub.
#
# Parameters:
#     NODE_VERSION: (default: 8.9.1)
#     NVM_VERSION: (default: 0.33.2)

NODE_VERSION="${NODE_VERSION:-8.9.1}"
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
