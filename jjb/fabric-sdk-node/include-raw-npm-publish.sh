#!/bin/bash -eu

#################################################
#Publish npm module as unstable after merge commit
#npm publish --tag unstable
#################################################

set -o pipefail

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-sdk-node
npm config set //registry.npmjs.org/:_authToken=$NPM_TOKEN

# Publish fabric-ca-client npm module as unstable
cd fabric-ca-client
FABRIC_CA_CLIENT_PKG_VER=$(cat package.json | grep version | awk -F\" '{ print $4 }')
echo "==> Fabric-ca-client npm version: =====>" $FABRIC_CA_CLIENT_PKG_VER
echo
npm publish --tag unstable

# Publish fabric-client npm module as unstable
cd ../fabric-client
echo
FABRIC_CLIENT_PKG_VER=$(cat package.json | grep version | awk -F\" '{ print $4 }')
echo "Fabric-client npm version: =====>" $FABRIC_CLIENT_PKG_VER
# Publish fabric-ca-client npm module as unstable
npm publish --tag unstable
