#!/bin/bash -eu
# Copyright the Hyperledger Fabric contributors. All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0
echo "----> include-raw-install-go-curl.sh"
wget -q "https://raw.githubusercontent.com/hyperledger/${PROJECT}/${GERRIT_BRANCH}/ci.properties"
GO_CI_VER=$(grep GO_VER ci.properties | cut -d "=" -f 2)
rm -rf ci.properties
echo "Installing Go v${GO_CI_VER}"
wget -q "https://dl.google.com/go/go${GO_CI_VER}.linux-amd64.tar.gz"
tar -xzf "go${GO_CI_VER}.linux-amd64.tar.gz"
rm -rf "go${GO_CI_VER}.linux-amd64.tar.gz"
mkdir -p "${WORKSPACE}/golang"
mv go/ "${WORKSPACE}/golang"
