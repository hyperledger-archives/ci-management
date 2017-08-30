#!/bin/bash -e
set -o pipefail

# Setup fabric sdk rest CI Configuration
if [ -d "${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples" ] ; then
        echo "Delete fabric-samples Directory"
	rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-samples
        echo
else
        echo "Create hyperledger Directory"
        mkdir -p gopath/src/github.com/hyperledger
fi

export WD="${WORKSPACE}/gopath/src/github.com/hyperledger"
SAMPLES_REPO_NAME=fabric-samples
cd $WD
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$SAMPLES_REPO_NAME && cd fabric-samples
COMMIT=ca8fad315128a528dc8f3eab2395105723d5f95b
# Checkout to Commit "$COMMIT"
git checkout $COMMIT
COMMIT_VALUE=$(git log --pretty=format:"%H" -n1)
if [ "$COMMIT_VALUE" == "$COMMIT" ] ; then
    echo "========== CHECKOUT SUCCESSFUL=========="
    echo
else
    echo "=========== ERROR !!! FAILED ==========="
    exit 1
fi

cd fabcar
./startFabric.sh

cd $WD && git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/fabric-sdk-rest && cd $WD/fabric-sdk-rest/packages/
# Install nvm
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
# Install 6.9.5 node js version
nvm install 6.9.5 || true
# use npm 6.9.5
nvm use 6.9.5
echo "npm version ====>" 
echo
npm -v
echo "nodejs version ==="
echo
node -v
npm install loopback-connector-fabric && npm install fabric-rest
cd ../

# Setup Data sources
./setup.sh -sukadf $WD/fabric-samples/basic-network &

sleep 30
# Run the fabric-sdk-rest tests
python tests/test_fabcar.py
