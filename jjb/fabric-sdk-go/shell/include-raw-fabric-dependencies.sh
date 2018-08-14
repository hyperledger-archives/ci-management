#!/bin/bash -exu
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

# shellcheck source=/dev/null
source ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-go/test/scripts/fabric_test_commitlevel.sh

if [ "$USE_PREBUILT_IMAGES" == false ]
then
  echo "Building custom images: Fabric commit is $FABRIC_COMMIT , Fabric-ca commit is $FABRIC_CA_COMMIT"
  # Clone fabric git repository
  #############################

  rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

  WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
  REPO_NAME=fabric
  git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
  cd $WD

  if [ "$FABRIC_COMMIT" == "latest" ]; then
        echo "Fabric commit is $FABRIC_COMMIT so go with this"
  else
        git checkout $FABRIC_COMMIT
        FABRIC_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
  fi
        FABRIC_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
        echo "=======>" "FABRIC COMMIT NUMBER" "-" $FABRIC_COMMIT_LEVEL

  # Build fabric Docker images
  make docker
  if [ $? != 0 ]; then
       echo "-----> make docker failed"
       exit 1
  fi
  docker images | grep hyperledger

  # Clone fabric-ca git repository
  ################################

  rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

  WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
  CA_REPO_NAME=fabric-ca
  git clone git://cloud.hyperledger.org/mirror/$CA_REPO_NAME $WD
  cd $WD
  if [ "$FABRIC_CA_COMMIT" == "latest" ]; then
        echo "Fabric_CA commit is $FABRIC_COMMIT so go with this"
  else
        git checkout $FABRIC_CA_COMMIT
        CA_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
  fi
        CA_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
        echo "=======>" "FABRIC CA COMMIT NUMBER" "-" $CA_COMMIT_LEVEL
  # Build CA Docker Images
  echo
  echo "----> Build fabric-ca docker images"
  make docker
  if [ $? != 0 ]; then
       echo "-----> make docker failed"
       exit 1
  fi
  docker images | grep hyperledger
fi

# Move to fabric-sdk-go repository and execute integration tests
export WD=${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-go
cd $WD
GO_SDK_COMMIT_LEVEL=$(git log -1 --pretty=format:"%h")
echo "=======>" "FABRIC SDK GO COMMIT NUMBER" "-" $GO_SDK_COMMIT_LEVEL >> commit_history.log
export GOPATH=${WORKSPACE}/gopath
make integration-test
