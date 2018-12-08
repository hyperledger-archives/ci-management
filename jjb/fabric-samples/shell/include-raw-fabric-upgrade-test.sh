#!/bin/bash

# docker container list
CONTAINER_LIST=(peer0.org1 peer1.org1 peer0.org2 peer1.org2 orderer)

cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-samples || exit

# Fetch Go Version from fabric ci.properties file
curl -L https://raw.githubusercontent.com/hyperledger/fabric/master/ci.properties > ci.properties
GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
export PATH=$GO_VER:$PATH
OS_VER=$(dpkg --print-architecture)
echo "------> ARCH: $OS_VER"
export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
export PATH=$GOROOT/bin:$PATH
echo "------> GO_VER" $GO_VER
 
ARCH=$(go env GOARCH)
export ARCH
ORG_NAME=hyperledger/fabric
export ORG_NAME
MARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
export MARCH

cd first-network || exit

# Create Logs directory
mkdir -p $WORKSPACE/Docker_Container_Logs

#Set INFO to DEBUG
sed -it 's/INFO/DEBUG/' base/peer-base.yaml

# Archive the container logs
artifacts() {

    echo "---> Archiving generated logs"
    rm -rf $WORKSPACE/archives
    mkdir -p "$WORKSPACE/archives"
    mv "$WORKSPACE/Docker_Container_Logs" $WORKSPACE/archives/
}

# Capture docker logs of each container
logs() {

for CONTAINER in ${CONTAINER_LIST[*]}; do
    docker logs $CONTAINER.example.com >& $WORKSPACE/Docker_Container_Logs/$CONTAINER-$2.log
    echo
done
}

copy_logs() {

# Call logs function
logs $2

if [ $1 != 0 ]; then
    artifacts
    exit 1
fi
}

pull_images () {
IMAGES_LIST=(peer orderer tools ccenv)
export IMAGES_LIST
   for IMAGES in ${IMAGES_LIST[*]}; do
       docker pull $DOCKER_REPOSITORY/fabric-$IMAGES:$ARCH-$FAB_REL_VER-stable
       docker tag $DOCKER_REPOSITORY/fabric-$IMAGES:$ARCH-$FAB_REL_VER-stable $ORG_NAME-$IMAGES:$ARCH-$FAB_REL_VER
   done
}

pull_prev_binary() {
    rm -rf $WORKSPACE/gopath/src/github.com/hyperledger/fabric-samples/first-network/bin
    curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/$MARCH-$FAB_PREV_VER/hyperledger-fabric-$MARCH-$FAB_PREV_VER.tar.gz | tar xz
    export PATH=$WORKSPACE/gopath/src/github.com/hyperledger/fabric-samples/first-network/bin:$PATH
    ls -l bin
    }

echo "##################### BYFN UPGRADE TEST #########################"
echo "#################################################################"
# Bring down the network
echo y | ./byfn.sh -m down
# Get the binaries
pull_prev_binary
# Start the BYFN test with previous version
git fetch origin
git checkout v$FAB_PREV_VER
echo y |./byfn.sh up -t 3000 -i $FAB_PREV_VER
# Archive the container log files
copy_logs $? default-channel
git fetch origin
# Verify if we need the latest images from Nexus
if [ $DOCKER_REPOSITORY != "hyperledger" ]; then
    git checkout $GERRIT_BRANCH
    pull_images
else
    git checkout v$FAB_REL_VER
fi
# Start the BYFN upgrade test with the latest images
echo y |./byfn.sh upgrade -i $FAB_REL_VER
copy_logs $? default-channel
# Bring down the network after all tests are executed
echo y | ./byfn.sh -m down
echo