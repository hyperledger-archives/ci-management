#!/bin/bash -e
set -o pipefail

# Test fabric-chaincode-node tests
##################################

REPO_PATH="${WORKSPACE}/gopath/src/github.com/hyperledger"
cd $REPO_PATH
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/fabric-samples
cd $REPO_PATH/fabric-chaincode-node

# Install nvm to install multi node versions
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
# shellcheck source=/dev/null
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion

# Install nodejs version 8.4.0
nvm install 8.4.0 || true

# Use nodejs 8.4.0 version
nvm use 8.4.0
echo "npm version ===>"
npm -v
echo "Node version ====>"
node -v
npm install
npm config set prefix ~/npm && npm install -g gulp

echo "###############"
echo "Run Unit-tests"
echo "###############"

gulp test-headless

echo "##############"
echo "Setup Integration Environment"
echo "##############"

DEVMODE=false gulp channel-init

echo "##############"
echo "Run Integration Tests"
echo "##############"

gulp test-e2e

# copy debug log file to $WORKSPACE directory

if [ $? == 0 ]; then
   # Copy Debug log to $WORKSPACE
   cp /tmp/fabric-shim/logs/*.log $WORKSPACE
else
   # Copy Debug log to $WORKSPACE
   cp /tmp/fabric-shim/logs/*.log $WORKSPACE
exit 1

fi
