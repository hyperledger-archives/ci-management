#!/bin/bash
echo
echo "Running SafeSQL scan"
echo

export FABRIC_CA_ROOT_DIR=$WORKSPACE/gopath/src/github.com/hyperledger/fabric-ca

cd $FABRIC_CA_ROOT_DIR || exit
go get github.com/stripe/safesql
./scripts/run_safesql_scan
