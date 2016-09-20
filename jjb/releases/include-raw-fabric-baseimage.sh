#!/bin/bash -eu
set -o pipefail

IS_RELEASE=`cat Makefile | grep IS_RELEASE | awk '{print $3 }'`
if [ "$IS_RELEASE" == "true" ];
then
	echo "Release detected!  Triggering release promotion"
    exit 0
fi

echo "SNAPSHOT release detected, skipping release promotion"
exit -1
