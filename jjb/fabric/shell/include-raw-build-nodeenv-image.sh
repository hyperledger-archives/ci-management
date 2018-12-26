#!/bin/bash
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
set -o pipefail

if [[ "$GERRIT_BRANCH" = "master" ]]; then

  echo -e "\033[32m Build Chaincode-nodeenv-image" "\033[0m"
  rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-chaincode-node
  WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-chaincode-node"
  REPO_NAME=fabric-chaincode-node
  git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
  cd $WD || exit

  NODE_VER=8.11.3
  wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | bash
  # shellcheck source=/dev/null
  export NVM_DIR="$HOME/.nvm"
  # shellcheck source=/dev/null
  [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
  echo "------> Install NodeJS"
  # Install NODE_VER
  echo "------> Use $NODE_VER"
  nvm install $NODE_VER || true
  nvm use --delete-prefix v$NODE_VER --silent
  npm install
  npm config set prefix ~/npm && npm install -g gulp

  echo -e "\033[32m npm version ------> $(npm -v)" "\033[0m"
  echo -e "\033[32m node version ------> $(node -v)" "\033[0m"

  gulp docker-image-build
  docker images | grep hyperledger && docker ps -a
else
  echo "========> SKIP: nodeenv image is not available on $GERRIT_BRANCH"
fi
