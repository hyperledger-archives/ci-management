#!/bin/bash -x
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

setEnvVars() {
  NEXUS_URL_REGISTRY=nexus3.hyperledger.org:10001
  ORG_NAME="hyperledger/fabric"
  ARCH=$(go env GOARCH)
  TAG=$GIT_COMMIT
  export CCENV_TAG=${TAG:0:7}
  cd ${GOPATH}/src/github.com/hyperledger/fabric || exit
  VERSION=$(make -f Makefile -f <(printf 'p:\n\t@echo $(BASE_VERSION)\n') p)
  echo "------> BASE_VERSION = $VERSION"
}

pullChaincodeJavaImage() {
  if [[ "$GERRIT_BRANCH" = "master" || "$GERRIT_BRANCH" = "release-1.4" || "$GERRIT_BRANCH" = "release-1.3" || "$ARCH" != "s390x" ]]; then

         #####################################
         # Pull fabric-javaenv Image

         NEXUS_URL_REGISTRY=nexus3.hyperledger.org:10001
         ORG_NAME="hyperledger/fabric"
         IMAGE=javaenv
         if [ "$GERRIT_BRANCH" = "master" ]; then
            export STABLE_VERSION=amd64-2.0.0-stable
            export JAVA_ENV_TAG=2.0.0
         elif [ "$GERRIT_BRANCH" = "release-1.4" ]; then
	    export STABLE_VERSION=amd64-1.4.0-stable
	    export JAVA_ENV_TAG=1.4.0
	 else
            export STABLE_VERSION=amd64-1.3.1-stable
            export JAVA_ENV_TAG=1.3.1
         fi
         docker pull $NEXUS_URL_REGISTRY/$ORG_NAME-$IMAGE:$STABLE_VERSION
         docker tag $NEXUS_URL_REGISTRY/$ORG_NAME-$IMAGE:$STABLE_VERSION $ORG_NAME-$IMAGE
         docker tag $NEXUS_URL_REGISTRY/$ORG_NAME-$IMAGE:$STABLE_VERSION $ORG_NAME-$IMAGE:amd64-$JAVA_ENV_TAG
         docker tag $NEXUS_URL_REGISTRY/$ORG_NAME-$IMAGE:$STABLE_VERSION $ORG_NAME-$IMAGE:amd64-latest
         ######################################
         docker images | grep hyperledger/fabric-javaenv || true

  else
        echo "========> SKIP: javaenv image is not available on $GERRIT_BRANCH or on $ARCH"
  fi
}

main() {
  setEnvVars
  pullChaincodeJavaImage
}

main
