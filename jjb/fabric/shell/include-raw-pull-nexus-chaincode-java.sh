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
# Pull javaenv images from nexus3 (docker.snapshot)
# javaenv image is available only on amd64
set -o pipefail

# Set NEXUS_URL_REGISTRY to docker.snapshot
NEXUS_URL_REGISTRY=nexus3.hyperledger.org:10001
ORG_NAME="hyperledger/fabric"
ARCH=$(go env GOARCH)
# fabric-chaincode-java (javaenv image name)
IMAGE=javaenv

pullChaincodeJavaImage() {

  if [ "$GERRIT_BRANCH" = "master" ]; then
    export JAVA_ENV_VERSION=amd64-2.0.0-stable
    export JAVA_ENV_TAG=2.0.0
  elif [ "$GERRIT_BRANCH" = "release-1.4" ]; then
    export JAVA_ENV_VERSION=amd64-1.4.0-stable
    export JAVA_ENV_TAG=1.4.0
  else
    export JAVA_ENV_VERSION=amd64-1.3.1-stable
    export JAVA_ENV_TAG=1.3.1
  fi
  # Pull javaenv images and tag them as latest, amd64-$JAVA_ENV_TAG, amd64-latest
  docker pull $NEXUS_URL_REGISTRY/$ORG_NAME-$IMAGE:$JAVA_ENV_VERSION
  docker tag $NEXUS_URL_REGISTRY/$ORG_NAME-$IMAGE:$JAVA_ENV_VERSION $ORG_NAME-$IMAGE
  docker tag $NEXUS_URL_REGISTRY/$ORG_NAME-$IMAGE:$JAVA_ENV_VERSION $ORG_NAME-$IMAGE:amd64-$JAVA_ENV_TAG
  docker tag $NEXUS_URL_REGISTRY/$ORG_NAME-$IMAGE:$JAVA_ENV_VERSION $ORG_NAME-$IMAGE:amd64-latest
  docker images | grep hyperledger/fabric-javaenv || true
}

main() {
  pullChaincodeJavaImage
}

# Skip javaenv pull on s390x and specific release branches
if [[ $ARCH != "s390x" ]]; then
  case $GERRIT_BRANCH in
     "master" | "release-1.3" | "release-1.4") main;;
     *)  echo -e "\033[32m ========> SKIP: javaenv image is not available on $GERRIT_BRANCH or on $ARCH \033[0m";;
  esac
else
  echo -e "\033[32m SKIP: javaenv image is not available on $ARCH \033[0m"
fi
