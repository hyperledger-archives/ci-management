#!/bin/bash -eu
#
# SPDX-License-Identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 IBM Corporation, The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License 2.0
# which accompanies this distribution, and is available at
# https://www.apache.org/licenses/LICENSE-2.0
##############################################################################

#################################################
#Publish npm module as unstable after merge commit
#npm publish --tag $CURRENT_TAG (unstable/latest)
#Run this "npm dist-tags ls $pkgs then look for
#versions tagged on $CURRENT_TAG
#################################################

set -o pipefail

npmPublish() {
  # Check if the tag contains "unstable"
  if [[ "$CURRENT_TAG" = *"unstable"* ]] || [[ "$CURRENT_TAG" = *"skip"* ]] ; then
    echo
    UNSTABLE_VER=$(npm dist-tags ls "$1" | awk "/$CURRENT_TAG"":"/'{
    ver=$NF
    sub(/.*\./,"",rel)
    sub(/\.[[:digit:]]+$/,"",ver)
    print ver}')
    echo "===> UNSTABLE VERSION --> $UNSTABLE_VER"

    # Increment the unstable version number by 1
    UNSTABLE_INCREMENT=$(npm dist-tags ls "$1" | awk "/$CURRENT_TAG"":"/'{
    ver=$NF
    rel=$NF
    sub(/.*\./,"",rel)
    sub(/\.[[:digit:]]+$/,"",ver)
    print ver"."rel+1}')
    echo "===> Incremented UNSTABLE VERSION --> $UNSTABLE_INCREMENT"

    # Get the last incremented digit of $CURRENT_TAG from npm
    UNSTABLE_INCREMENT=$(echo $UNSTABLE_INCREMENT| rev | cut -d '.' -f 1 | rev)
    echo "--------> UNSTABLE_INCREMENT : $UNSTABLE_INCREMENT"

    # Append incremented number to the version in package.json
    export UNSTABLE_INCREMENT_VERSION=$RELEASE_VERSION.$UNSTABLE_INCREMENT
    echo "--------> UNSTABLE_INCREMENT_VERSION" $UNSTABLE_INCREMENT_VERSION

    # Replace the existing version with $UNSTABLE_INCREMENT_VERSION
    sed -i 's/\(.*\"version\"\: \"\)\(.*\)/\1'$UNSTABLE_INCREMENT_VERSION\"\,'/' package.json
    npm publish --tag $CURRENT_TAG

  else

    echo "----> Publishing $CURRENT_TAG from fabric-chaincode-node-npm-release-x86_64"
fi
}
versions() {
  # grep on "tag" from package.json
  CURRENT_TAG=$(cat package.json | grep tag | awk -F\" '{ print $4 }')
  echo "===> Current Version --> $CURRENT_TAG"

  # grep on version from package.json
  RELEASE_VERSION=$(cat package.json | grep version | awk -F\" '{ print $4 }')
  echo "===> Current Version --> $RELEASE_VERSION"

}

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-chaincode-node
npm config set //registry.npmjs.org/:_authToken=$NPM_TOKEN

if [[ "$GERRIT_BRANCH" = "release-1.1" || "$GERRIT_BRANCH" = "release-1.2" ]]; then
   cd src
else
   cd fabric-shim
fi
versions
npmPublish fabric-shim

cd ../fabric-shim-crypto
versions
npmPublish fabric-shim-crypto

if [ "$GERRIT_BRANCH" = "master" ]; then
   cd ../fabric-contract-api
   versions
   npmPublish fabric-contract-api
fi
