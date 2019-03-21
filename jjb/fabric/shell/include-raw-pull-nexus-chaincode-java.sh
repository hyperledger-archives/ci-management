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
# Pull javaenv images from nexus3 (docker.snapshot) if the branch is master
# Pull javaenv images from dockerhub if the branch is release
# javaenv image is available only on amd64
set -o pipefail

REPO="fabric"
# fabric-chaincode-java (javaenv image name)
IMAGE=javaenv
echo "#######################"
echo -e "\033[1m P U L L - J A V A E N V\033[0m"
echo "#######################"
echo
pulljavaenv() {
   # Pull javaenv images and tag them as latest, amd64-$JAVA_ENV_TAG, amd64-latest
   docker pull $1/$REPO-$IMAGE:$JAVA_ENV_VERSION
   docker tag $1/$REPO-$IMAGE:$JAVA_ENV_VERSION hyperledger/$REPO-$IMAGE
   docker tag $1/$REPO-$IMAGE:$JAVA_ENV_VERSION hyperledger/$REPO-$IMAGE:amd64-$JAVA_ENV_TAG
   docker tag $1/$REPO-$IMAGE:$JAVA_ENV_VERSION hyperledger/$REPO-$IMAGE:amd64-latest
   docker images | grep hyperledger/fabric-javaenv
}

pullChaincodeJavaImage() {

  if [ "$GERRIT_BRANCH" = "master" ]; then
     export JAVA_ENV_VERSION=amd64-2.0.0-stable
     export JAVA_ENV_TAG=2.0.0
     pulljavaenv nexus3.hyperledger.org:10001/hyperledger
  elif [ "$GERRIT_BRANCH" = "release-1.4" ]; then
     export JAVA_ENV_VERSION=amd64-1.4.0
     export JAVA_ENV_TAG=1.4.0
     pulljavaenv hyperledger
  else
     export JAVA_ENV_VERSION=amd64-1.3.0
     export JAVA_ENV_TAG=1.3.0
     pulljavaenv hyperledger
  fi
}

main() {
  pullChaincodeJavaImage
}

# Skip javaenv pull on s390x and specific release branches
if [[ $ARCH != "s390x" ]]; then
  case $GERRIT_BRANCH in
    "master" | "release-1.3" | "release-1.4") main
    ;;
    *)  echo -e "\033[1;32m ========> SKIP: javaenv image is not available on $GERRIT_BRANCH or on $ARCH \033[0m"
    ;;
  esac
else
  echo -e "\033[32m SKIP: javaenv image is not available on $ARCH \033[0m"
fi
