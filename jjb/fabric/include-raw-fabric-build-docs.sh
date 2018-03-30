#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> tox-install.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u as virtualenv's activate script has unbound variables
set -e -o pipefail

virtualenv --quiet -p "$PYTHON_VERSION" "/tmp/v/tox"
# shellcheck source=/tmp/v/tox/bin/activate disable=SC1091
source "/tmp/v/tox/bin/activate"
pip install --quiet --upgrade pip
pip install --quiet --upgrade pipdeptree
pip install --quiet --upgrade argparse detox tox tox-pyenv

echo "----> Pip Dependency Tree"
pipdeptree

#!/bin/bash
# SPDX-License-Identifier: EPL-1.0
##############################################################################
# Copyright (c) 2017 The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Eclipse Public License v1.0
# which accompanies this distribution, and is available at
# http://www.eclipse.org/legal/epl-v10.html
##############################################################################
echo "---> rtd-verify.sh"

# Ensure we fail the job if any steps fail.
# DO NOT set -u
set -xe -o pipefail

echo "---> Generating docs"
cd "$GOPATH/src/github.com/hyperledger/fabric" || exit
tox -edocs

echo "---> Archiving generated docs"
mkdir -p "$WORKSPACE/archives"
cd -

mv $GOPATH/src/github.com/hyperledger/fabric/docs/_build/html archives/

res=$(echo $?)
if [ $res = 0 ]; then
     ssh -p 29418 hyperledger-jobbuilder@$GERRIT_HOST gerrit review $GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER -m '"Succeeded"' -l F2-DocBuild=+1
else
     ssh -p 29418 hyperledger-jobbuilder@$GERRIT_HOST gerrit review $GERRIT_CHANGE_NUMBER,$GERRIT_PATCHSET_NUMBER -m '"Failed"' -l F2-DocBuild=-1
     exit 1
fi

