#!/bin/bash
set -o pipefail

cd gopath/src/github.com/hyperledger/fabric || exit

IS_RELEASE=`cat Makefile | grep IS_RELEASE | awk '{print $3 }'`

echo "==========>" $IS_RELEASE
if [ "$IS_RELEASE" == "true" ];
then
       echo "Release detected!  Triggering release promotion"
    exit 0
fi

echo "SNAPSHOT release detected, skipping release promotion"
exit -1
