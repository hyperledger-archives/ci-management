#!/bin/bash -eu
set -o pipefail

cd gopath/src/github.com/hyperledger/fabric

# script
echo "Executing Behave test scripts"
make behave BEHAVE_OPTS="-D logs=Y -o testsummary.log --junit --format=pretty"
