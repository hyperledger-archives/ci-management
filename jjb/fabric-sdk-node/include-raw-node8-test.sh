#!/bin/bash -e

# Clone fabric git repository
#############################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
REPO_NAME=fabric
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$REPO_NAME $WD
cd $WD || exit
set +e
BRANCH_NAME=$(echo $GERRIT_BRANCH | grep 'release-')
echo "-----> $BRANCH_NAME"
if [ ! -z "$BRANCH_NAME" ]; then
      echo "-----> Checkout to $GERRIT_BRANCH branch"
      git checkout $GERRIT_BRANCH
fi
set -e
echo "-----> $GERRIT_BRANCH"
#sed -i -e 's/127.0.0.1:7050\b/'"orderer:7050"'/g' $WD/common/configtx/tool/configtx.yaml
FABRIC_COMMIT=$(git log -1 --pretty=format:"%h")
echo "=======> FABRIC_COMMIT <======= $FABRIC_COMMIT"

# export fabric go version
GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
OS_VER=$(dpkg --print-architecture)
echo "-----> ARCH: $OS_VER"
export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
export PATH=$GOROOT/bin:$PATH
echo "----> GO_VER" $GO_VER
set +e
BRANCH_NAME=$(echo $GERRIT_BRANCH | grep 'release-')
echo "-----> $BRANCH_NAME"
if [ ! -z "$BRANCH_NAME" ]; then

     for IMAGES in docker release-clean release; do
        make $IMAGES
        if [ $? != 0 ]; then
           echo "-------> make $IMAGES failed"
           exit 1
        fi
     done

else

     for IMAGES in docker docker-thirdparty; do
         make $IMAGES
         if [ $? != 0 ]; then
            echo "-----> make $IMAGES failed"
            exit 1
         fi
done

fi
docker images | grep hyperledger || true
set -e
# Clone fabric-ca git repository
################################

rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca

WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-ca"
CA_REPO_NAME=fabric-ca
git clone ssh://hyperledger-jobbuilder@gerrit.hyperledger.org:29418/$CA_REPO_NAME $WD
cd $WD || exit
set +e
BRANCH_NAME=$(echo $GERRIT_BRANCH | grep 'release-')
echo "----> BRANCH_NAME"
if [ ! -z "$BRANCH_NAME" ]; then
      echo "-----> Checkout to $GERRIT_BRANCH branch"
      git checkout $GERRIT_BRANCH
fi
set -e
echo "-----> $GERRIT_BRANCH"
CA_COMMIT=$(git log -1 --pretty=format:"%h")
echo "======> CA_COMMIT <======= $CA_COMMIT"
set +x
GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
OS_VER=$(dpkg --print-architecture)
echo "-----> ARCH: $OS_VER"
export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
export PATH=$GOROOT/bin:$PATH
echo "----> GO_VER" $GO_VER
set -x
make docker-fabric-ca
if [ $? != 0 ]; then
   echo "-----> docker-fabric-ca failed"
   exit 1
fi
docker images | grep hyperledger || true

## Test fabric-sdk-node tests
################################

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node/test/fixtures || exit
docker-compose up >> dockerlogfile.log 2>&1 &
sleep 30
docker ps -a

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric-sdk-node || exit

# Install nvm to install multi node versions
wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.33.2/install.sh | bash
# shellcheck source=/dev/null
export NVM_DIR="$HOME/.nvm"
# shellcheck source=/dev/null
[ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh"  # This loads nvm
# Install nodejs version 8.9.4
nvm install 8.9.4 || true

# use nodejs 8.9.4 version
nvm use --delete-prefix v8.9.4 --silent

echo "npm version ======>"
npm -v
echo "node version =======>"
node -v

npm install
npm config set prefix ~/npm && npm install -g gulp && npm install -g istanbul
gulp || exit 1
gulp ca || exit 1
rm -rf node_modules/fabric-ca-client && npm install

# Execute unit test and code coverage
echo "############"
echo "Run unit tests and Code coverage report"
echo "############"

gulp test

# copy debug log file to $WORKSPACE directory
if [ $? == 0 ]; then

# Copy Debug log to $WORKSPACE
cp /tmp/hfc/test-log/*.log $WORKSPACE
else
# Copy Debug log to $WORKSPACE
cp /tmp/hfc/test-log/*.log $WORKSPACE
exit 1

fi
