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

# Clone fabric git repository
#############################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
REPO_NAME=fabric
git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
cd $WD || exit
#sed -i -e 's/127.0.0.1:7050\b/'"orderer:7050"'/g' $WD/common/configtx/tool/configtx.yaml
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "=======> FABRIC_COMMIT <======= $FABRIC_COMMIT"
make peer-docker && make orderer-docker && make couchdb && make ccenv
docker images | grep hyperledger

# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone git://cloud.hyperledger.org/mirror/$CA_REPO_NAME $WD
cd $WD || exit
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "======> CA_COMMIT <======= $CA_COMMIT"
make docker-fabric-ca
docker images | grep hyperledger

## Test gulp test
cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node/test/fixtures || exit
docker-compose up >> dockerlogfile.log 2>&1 &
sleep 30
docker ps -a

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
npm config set prefix ~/npm && npm install -g gulp && npm install -g istanbul
gulp || exit 1
gulp ca || exit 1
rm -rf node_modules/fabric-ca-client && npm install
gulp test

# copy debug log file to $WORKSPACE directory

if [ $? == 0 ]; then

# Copy Debug log to $WORKSPACE
cp /tmp/hfc/test-log/*.log $WORKSPACE
else
# Copy Debug log to $WORKSPACE
cp /tmp/hfc/test-log/*.log $WORKSPACE
exit 1

fi
