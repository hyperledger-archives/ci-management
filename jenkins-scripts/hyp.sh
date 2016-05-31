#!/bin/bash -eu
set -o pipefail

# Cache base docker image
docker pull hyperledger/fabric-baseimage:x86_64-0.0.10
