#!/bin/bash -exu
set -o pipefail

export WD=${WORKSPACE}
export GOPATH=$WD/src/test/fixture
cd $GOPATH
export ORG_HYPERLEDGER_FABRIC_SDKTEST_VERSION="1.0.0"
cd $WD/src/test
chmod +x cirun.sh
source cirun.sh
