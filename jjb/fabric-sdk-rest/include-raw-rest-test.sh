#!/bin/bash -e
set -o pipefail

cd gopath/src/github.com/hyperledger/fabric-sdk-rest/packages || exit
# Install nvm
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
# Install 6.9.5 node js version
nvm install 6.9.5 || true
# use npm 6.9.5
nvm use --delete-prefix v6.9.5 --silent
echo "npm version ====>"
echo
npm -v
echo "nodejs version ====>"
echo
node -v
npm install loopback-connector-fabric && npm install fabric-rest

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-sdk-rest || exit

npm install
# Run the fabric-sdk-rest tests
./tests/fullRun.sh
