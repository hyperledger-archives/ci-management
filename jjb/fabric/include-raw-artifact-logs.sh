#!/bin/bash -eu
set -o pipefail

echo "---> Archiving generated logs"
mkdir -p "$WORKSPACE/archives"
mv "$WORKSPACE/Docker_Container_Logs" archives/
