#!/bin/bash -exu
set -o pipefail

export WD=${WORKSPACE}
export GOPATH=$WD/src/test/fixture
cd $GOPATH
# Commentout the Image reference from .env file
sed -i '16,17 s/^/#/' sdkintegration/.env
export IMAGE_TAG_FABRIC=:x86_64-1.0.0
export IMAGE_TAG_FABRIC_CA=:x86_64-1.0.0
#export ORG_HYPERLEDGER_FABRIC_SDKTEST_ITSUITE="-Dorg.hyperledger.fabric.sdktest.ITSuite=IntegrationSuiteV1.java"
export ORG_HYPERLEDGER_FABRIC_SDKTEST_VERSION="1.0.0"
cd $WD/src/test
chmod +x cirun.sh
source cirun.sh
