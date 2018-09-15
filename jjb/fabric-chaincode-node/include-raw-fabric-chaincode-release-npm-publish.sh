#!/bin/bash -e
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

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-chaincode-node
npm config set //registry.npmjs.org/:_authToken=$NPM_TOKEN

cd fabric-shim
versions
npmPublish fabric-shim

cd ../fabric-shim-crypto
versions
npmPublish fabric-shim-crypto
