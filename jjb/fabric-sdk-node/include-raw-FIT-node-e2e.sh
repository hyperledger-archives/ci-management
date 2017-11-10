#!/bin/bash -e
set -o pipefail

# RUN END-to-END Test
#####################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node"
SDK_REPO_NAME=fabric-sdk-node
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$SDK_REPO_NAME $WD
cd $WD
NODE_SDK_COMMIT=$(git log -1 --pretty=format:"%h")

echo "FABRIC NODE SDK COMMIT ========> " $NODE_SDK_COMMIT >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit_history.log

cd test/fixtures
cat docker-compose.yaml > docker-compose.log
docker-compose up >> dockerlogfile.log 2>&1 &
sleep 10
docker ps -a
cd ../..

# Install nvm to install multi node versions
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
# Install nodejs version 6.9.5
nvm install 6.9.5 || true

# use nodejs 6.9.5 version
nvm use --delete-prefix v6.9.5 --silent

echo "npm version ======>"
npm -v
echo "node version =======>"
node -v

npm install
npm config set prefix ~/npm && npm install -g gulp && npm install -g istanbul
gulp && gulp ca
rm -rf node_modules/fabric-ca-client && npm install

# Execute unit test and code coverage
echo "############"
echo "Run e2e tests and Code coverage report"
echo "############"

istanbul cover --report cobertura test/integration/e2e.js

docker rm -f "$(docker ps -aq)" || true
