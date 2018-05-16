#!/bin/bash -e
set -o pipefail

# RUN END-to-END Test
#####################
rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node"
SDK_REPO_NAME=fabric-sdk-node
git clone git://cloud.hyperledger.org/mirror/$SDK_REPO_NAME $WD
cd $WD

# error check
err_check() {
echo "--------> $1 <---------"
exit 1
}

# Checkout to GERRIT_BRANCH
if [[ "$GERRIT_BRANCH" = *"release-"* ]]; then # any release branch
      echo "-----> Checkout to $GERRIT_BRANCH branch"
      git checkout $GERRIT_BRANCH
fi
echo "-----> $GERRIT_BRANCH"

SDK_NODE_COMMIT=$(git log -1 --pretty=format:"%h")
echo "------> SDK_NODE_COMMIT : $SDK_NODE_COMMIT"
echo "SDK_NODE_COMMIT=======> $SDK_NODE_COMMIT" >> ${WORKSPACE}/gopath/src/github.com/hyperledger/commit.log
cd test/fixtures
docker rm -f "$(docker ps -aq)" || true
docker-compose up >> node_dockerlogfile.log 2>&1 &
sleep 10
docker ps -a
cd ../..

# Install nvm to install multi node versions
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm

echo "-------> Install NodeJS"

# Checkout to GERRIT_BRANCH
if [[ "$GERRIT_BRANCH" = *"release-1.0"* ]]; then # Only on release-1.0 branch
    NODE_VER=6.9.5
    # Install nodejs version $NODE_VER
    nvm install $NODE_VER || true
    # use nodejs 6.9.5 version
    nvm use --delete-prefix v$NODE_VER --silent
else
    NODE_VER=8.9.4
    echo "-----> use $NODE_VER for master and release-1.1 branches"
    nvm install $NODE_VER || true
    # use nodejs 8.9.4 version
    nvm use --delete-prefix v$NODE_VER --silent
fi

echo "npm version ======>"
npm -v
echo "node version =======>"
node -v

npm install || err_check "npm install failed"
npm config set prefix ~/npm || exit 1
npm install -g gulp || exit 1
npm install -g istanbul || exit 1

gulp || err_check "gulp failed"
gulp ca || err_check "gulp ca failed"

rm -rf node_modules/fabric-ca-client && npm install || err_check "npm install failed"

# Execute e2e tests and code coverage report

echo "#######################################"
echo "Run e2e tests and Code coverage report"
echo "#######################################"

istanbul cover --report cobertura test/integration/e2e.js

function clearContainers () {
    CONTAINER_IDS=$(docker ps -aq)
        if [ -z "$CONTAINER_IDS" ] || [ "$CONTAINER_IDS" = " " ]; then
                echo "---- No containers available for deletion ----"
        else
                docker rm -f $CONTAINER_IDS || true
                docker ps -a
        fi
}

function removeUnwantedImages() {
        DOCKER_IMAGE_IDS=$(docker images | grep "dev\|none\|test-vp\|peer[0-9]-" | awk '{print $3}')
        if [ -z "$DOCKER_IMAGE_IDS" ] || [ "$DOCKER_IMAGE_IDS" = " " ]; then
                echo "---- No images available for deletion ----"
        else
                docker rmi -f $DOCKER_IMAGE_IDS || true
                docker images
        fi
}

clearContainers
removeUnwantedImages
