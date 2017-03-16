#!/bin/bash -eu

#################################################
#Publish npm module as unstable after merge commit
#npm publish --tag unstable
#Run this "npm view fabric-ca-client" then look for
#"dist-tags"
#################################################

set -o pipefail

npmPublish() {

BASE_VERSION=$(echo $CURRENT_VER | cut -d"." -f1-2)
VER_INCREMENT=$(echo $CURRENT_VER | cut -d"." -f3)
INCREMENT=`expr $VER_INCREMENT + 1`
sed -i 's/\(.*\"version\"\: \"'$BASE_VERSION'\)\(.*\)/\1.'$INCREMENT\"\,'/' package.json
NEW_RELEASE=$(cat package.json | grep version | awk -F\" '{ print $4 }')
echo "===> $NEW_RELEASE"
echo
echo "===> Publish $NEW_RELEASE as unstable"
npm publish --tag unstable

}

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-sdk-node
npm config set //registry.npmjs.org/:_authToken=$NPM_TOKEN

cd fabric-ca-client
echo
CURRENT_VER=$(npm show fabric-ca-client@* version |  tail -1 | awk '{print $1}' | cut -d '@' -f 2)
echo "===> Current Fabric-ca-client version $CURRENT_VER"
npmPublish

cd ../fabric-client
echo
CURRENT_VER=$(npm show fabric-client@* version |  tail -1 | awk '{print $1}' | cut -d '@' -f 2)
echo "===> Current Fabric-client version $CURRENT_VER"
npmPublish
