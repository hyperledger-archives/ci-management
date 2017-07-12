#!/bin/bash -eu
set -o pipefail

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

# Create virtual Environment to test behave tests

virtualenv -p /usr/bin/python2.7 venv
export PS1="test"
export VIRTUALENVWRAPPER_PYTHON=/usr/bin/python2.7
source venv/bin/activate

# Install all required python modules

pip install behave
pip install grpcio-tools
pip install "pysha3==1.0b1"
pip install b3j0f.aop
pip install jinja2
pip install pyopenssl
pip install ecdsa
pip install python-slugify
pip install pyyaml

# Build Peer and images
curl -sSL https://goo.gl/iX9dek | bash
docker images | grep hyperledger
cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/test/feature
behave --junit --junit-directory test/regression/daily/. --tags=-skip --tags=daily
cd -
deactivate
