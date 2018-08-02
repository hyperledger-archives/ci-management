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
# gladlew build from fabric-chaincode-java repo
./gradlew build
#./gradlew :shim:publishShimJarPublicationToHyperledgerNexusSnapshotRepository
./gradlew -Pmaven.settings.location=${MAVEN_SETTINGS_LOCATION} :fabric-chaincode-shim:publishShimJarPublicationToHyperledger-snapshotsRepository
