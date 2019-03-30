#!/bin/bash
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

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

virtualenv --quiet -p "$PYTHON_VERSION" "/tmp/v/tox"
# shellcheck source=/tmp/v/tox/bin/activate disable=SC1091
source "/tmp/v/tox/bin/activate"
pip install --quiet --upgrade pip setuptools
pip install --quiet --upgrade argparse detox "tox==3.5.0" tox-pyenv
echo "-------> tox VERSION"
tox --version
echo "---> rtd-verify.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u
set -xe -o pipefail

vote(){
     ssh -p 29418 hyperledger-jobbuilder@$GERRIT_HOST gerrit review \
          $GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER \
          --notify '"NONE"' \
          "$@"
}

post_Result() {
if [ $1 = 0 ]; then
     vote -m '"Succeeded. View staged documentation on the logs server linked below."' -l F2-DocBuild=+1
else
     vote -m '"Failed"' -l F2-DocBuild=-1
     exit 1
fi
}

set +e

vote -m '"Starting documentation build"' -l F2-DocBuild=0

echo "\033[1m---> Generating docs\033[0m"
cd "$GOPATH/src/github.com/hyperledger/fabric" || exit
tox -edocs
post_Result $?

echo "---> Archiving generated docs"
rm -rf $WORKSPACE/archives
mkdir -p "$WORKSPACE/archives"
cd -
mv $GOPATH/src/github.com/hyperledger/fabric/docs/_build/html archives/
post_Result $?
set -e
