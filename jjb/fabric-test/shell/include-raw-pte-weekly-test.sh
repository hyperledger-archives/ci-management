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

checkout_project() {
  rm -rf $WORKSPACE/gopath/src/github.com/hyperledger/fabric-test
  WD="$WORKSPACE/gopath/src/github.com/hyperledger/fabric-test"
  FABRIC_TEST_REPO_NAME=fabric-test
  git clone git://cloud.hyperledger.org/mirror/$FABRIC_TEST_REPO_NAME $WD
  cd $WD
  git checkout $GERRIT_BRANCH
}

get_release_commit() {
  MVN_METADATA=$(echo "https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-$STABLE_VERSION/maven-metadata.xml")
  curl -L "$MVN_METADATA" > maven-metadata.xml
  RELEASE_TAG=$(cat maven-metadata.xml | grep release)
  RELEASE_COMMIT=$(echo $RELEASE_TAG | awk -F - '{ print $4 }' | cut -d "<" -f1)
  export RELEASE_COMMIT
  echo "---------> RELEASE_COMMIT:" $RELEASE_COMMIT
}

run_12hr_pte_test() {
  cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-test
  # Fetch Go Version from fabric ci.properties file
  curl -L https://raw.githubusercontent.com/hyperledger/fabric/$GERRIT_BRANCH/ci.properties > ci.properties
  GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
  export GO_VER
  OS_VER=$(dpkg --print-architecture)
  echo "------> ARCH: $OS_VER"
  export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
  export PATH=$GOROOT/bin:$PATH
  echo "------> GO_VER" $GO_VER
  # Execute Make target from fabric-test Makefile
  make svt-weekly-pte-12hr-test
}

main() {
  checkout_project
  get_release_commit
  run_12hr_pte_test
}

main
