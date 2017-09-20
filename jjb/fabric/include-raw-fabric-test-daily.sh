#!/bin/bash -eu
set -o pipefail

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-test

git submodule update --init --recursive

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
pip install "pyopenssl==17.2.0"
pip install ecdsa
pip install python-slugify
pip install pyyaml
pip install pykafka
pip install requests
pip install pyexecjs
pip install pyjnius

cd regression/daily

echo "==========> Ledger component performance tests..."
py.test -v --junitxml results_ledger_lte.xml ledger_lte.py

echo "==========> System Test Performance Stress tests driven by PTE tool..."
py.test -v --junitxml results_systest_pte.xml systest_pte.py

# Execute behave smoke tests
cd ../../feature
behave --junit --junit-directory . -t daily
cd -
deactivate

