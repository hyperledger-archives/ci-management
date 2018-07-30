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
npm config set //registry.npmjs.org/:_authToken=$NPM_TOKEN

#cd fabric-ca-client
#versions
#npmPublish fabric-ca-client

cd ../fabric-client
versions
npmPublish fabric-client
