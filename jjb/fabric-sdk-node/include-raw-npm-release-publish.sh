#!/bin/bash -e

# This script supports only stable fabric-client and fabric-ca-client npm modules
# publish snapshot version through merge jobs

set -o pipefail

npmPublish() {
  if [ $RELEASE = "snapshot" ]; then
    echo "----> Ignore the release as this is a snapshot"
    echo "----> Merge job publish the snapshot releases"
  else
      if [[ "$RELEASE" =~ alpha*|preview*|beta*|rc*|^[0-9].[0-9].[0-9]$ ]]; then
        echo "===> PUBLISH --> $RELEASE"
        npm publish
      else
        echo "$RELEASE: No such release."
        exit 1
      fi
  fi
}

versions() {

  CURRENT_RELEASE=$(cat package.json | grep version | awk -F\" '{ print $4 }')
  echo "===> Current Version --> $CURRENT_RELEASE"

  RELEASE=$(cat package.json | grep version | awk -F\" '{ print $4 }' | cut -d "-" -f 2)
  echo "===> Current Release --> $RELEASE"
}

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-sdk-node

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

npm config set //registry.npmjs.org/:_authToken=$NPM_TOKEN

cd fabric-ca-client
versions
npmPublish fabric-ca-client

cd ../fabric-client
versions
npmPublish fabric-client
