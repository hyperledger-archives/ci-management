#!/bin/bash -eu
# Copyright the Hyperledger Fabric contributors. All rights reserved.
#
# SPDX-License-Identifier: Apache-2.0
echo "----> include-raw-install-go.sh"
GO_CI_VER=$(grep "GO_VER" "${GOPATH}/src/github.com/hyperledger/${PROJECT}/ci.properties" | cut -d'=' -f2-)
echo "Installing Go v${GO_CI_VER}"
wget -q "https://dl.google.com/go/go${GO_CI_VER}.linux-amd64.tar.gz"
tar -xzf "go${GO_CI_VER}.linux-amd64.tar.gz"
rm -rf "go${GO_CI_VER}.linux-amd64.tar.gz"
mkdir -p "${WORKSPACE}/golang"
mv go/ "${WORKSPACE}/golang"
