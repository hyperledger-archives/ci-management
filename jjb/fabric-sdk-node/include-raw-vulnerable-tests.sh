#!/bin/bash -e
set -o pipefail

## Test fabric-sdk-node tests
################################

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node || exit

# Install nvm to install multi node versions
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
# Install nodejs version 8.9.4
nvm install 8.9.4 || true

# use nodejs 8.9.4 version
nvm use --delete-prefix v8.9.4 --silent

echo "npm version ======>"
npm -v
echo "node version =======>"
node -v

npm install
npm config set prefix ~/npm && npm install -g nsp
cd fabric-client && nsp check --output summary

if [ $? -eq 0 ] ; then

     echo " ===> PASS !!! No vulnerable errors found on fabric-client"
     echo " ===> Execute vulnerable tests on fabric-ca-client"

cd ../fabric-ca-client && nsp check --output summary

if [ $? -eq 0 ] ; then
     echo " ===> PASS !!! No vulnerable errors found on fabric-ca-client"
     echo
  else
     echo " ===> ERROR!! Found vulnerable errors found"

fi
fi

