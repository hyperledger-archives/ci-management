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
set -o pipefail

echo "----> include-raw-fabric-clean-environment.sh"

clearContainers () {
        CONTAINER_IDS=$(docker ps -aq)
        if [ -z "$CONTAINER_IDS" ] || [ "$CONTAINER_IDS" = " " ]; then
             echo "---- No containers available for deletion ----"
        else
             docker rm -f $CONTAINER_IDS
             echo -e "\033[32m Docker Container List \033[0m"
             docker ps -a
        fi
}

base_image="0.4.13"
removeUnwantedImages() {
        # Delete <none> images
        docker images | grep none | awk '{ print $3; }' | xargs docker rmi || true
        # Get the latest baseimage version from Makefile of fabric master branch
        curl -L https://raw.githubusercontent.com/hyperledger/fabric/master/Makefile > Makefile
        # Fetch baseimage release version
        BASE_IMAGE=$(cat Makefile | grep "BASEIMAGE_RELEASE =" | awk '{print $3}')
        # Deleete Makefile
        rm -rf Makefile
        # Delete all docker images except the latest one fetched from fabric master Makefile
        IMAGE_IDS=$(docker images | grep -v "$base_image\|$BASE_IMAGE" | awk 'NR>1 {print $3}')
        if [[ -z ${IMAGE_IDS// } ]]; then
             echo "---- No Images available for deletion ----"
        else
             # Delete all list docker images
             docker rmi -f $IMAGE_IDS
             echo -e "\033[32m Docker Images List \033[0m"
             docker images
        fi
}

# Remove /tmp/fabric-shim as root permissions set on it. see FABCI-61
docker run -v /tmp:/tmp library/alpine rm -rf /tmp/fabric-shim

# remove leftovers from the previous builds
rm -rf /home/jenkins/npm /tmp/fabric-shim /tmp/hfc* /tmp/npm* /home/jenkins/kvsTemp /home/jenkins/.hfc-key-store
rm -rf /var/hyperledger/*

clearContainers
removeUnwantedImages
