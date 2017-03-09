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

make peer && make peer-docker && make orderer-docker
docker images | grep hyperledger
cd bddtests
behave -k -D cache-deployment-spec
#behave -k -D cache-deployment-spec features/bootstrap.feature
# Deactivate vitrualenv after behave test
deactivate
