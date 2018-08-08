#!/bin/bash

# docker container list
CONTAINER_LIST=(peer0.org1 peer1.org1 peer0.org2 peer1.org2 peer0.org3 peer1.org3 orderer)
COUCHDB_CONTAINER_LIST=(couchdb0 couchdb1 couchdb2 couchdb3 couchdb4 couchdb5)

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

cd first-network || exit

# Create Logs directory
mkdir -p $WORKSPACE/Docker_Container_Logs

#Set INFO to DEBUG
sed -it 's/INFO/DEBUG/' base/peer-base.yaml

export PATH=$WORKSPACE/gopath/src/github.com/hyperledger/fabric-samples/first-network/bin:$PATH

artifacts() {

    echo "---> Archiving generated logs"
    rm -rf $WORKSPACE/archives
    mkdir -p "$WORKSPACE/archives"
    mv "$WORKSPACE/Docker_Container_Logs" $WORKSPACE/archives/
}

# Capture docker logs of each container
logs() {

for CONTAINER in ${CONTAINER_LIST[*]}; do
    docker logs $CONTAINER.example.com >& $WORKSPACE/Docker_Container_Logs/$CONTAINER-$1.log
    echo
done

if [ ! -z $2 ]; then

    for CONTAINER in ${COUCHDB_CONTAINER_LIST[*]}; do
        docker logs $CONTAINER >& $WORKSPACE/Docker_Container_Logs/$CONTAINER-$1.log
        echo
    done
fi
}

copy_logs() {

# Call logs function
logs $2 $3

if [ $1 != 0 ]; then
    artifacts
    exit 1
fi
}

binaries_110 () {

# pull 1.1.0 binaries
cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-samples/first-network || exit
rm -rf $WORKSPACE/gopath/src/github.com/hyperledger/fabric-samples/first-network/bin
curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/linux-amd64-1.1.0/hyperledger-fabric-linux-amd64-1.1.0.tar.gz | tar xz
export PATH=$WORKSPACE/gopath/src/github.com/hyperledger/fabric-samples/first-network/bin:$PATH
ls bin/
echo "Binaries v1.1.0"
}

binaries_120 () {

# pull 1.2.0 binaries
cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric-samples/first-network || exit
rm -rf $WORKSPACE/gopath/src/github.com/hyperledger/fabric-samples/first-network/bin
curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric/linux-amd64-1.2.0/hyperledger-fabric-linux-amd64-1.2.0.tar.gz | tar xz
export PATH=$WORKSPACE/gopath/src/github.com/hyperledger/fabric-samples/first-network/bin:$PATH
ls bin/
echo "Binaries v1.2.0"
}

echo "------> Deleting Containers...."
# shellcheck disable=SC2046
docker rm -f $(docker ps -aq)
echo "------> List Docker Containers"
docker ps -aq

# Execute below tests
echo "------> BRANCH: " $GERRIT_BRANCH

        echo "##################### BYFN UPGRADE TEST #########################"
        echo "#################################################################"
        echo y | ./byfn.sh -m down
        git checkout v1.1.0
        binaries_110
        echo y |./byfn.sh up -t 3000 -i 1.1.0
        copy_logs $? default-channel
        git fetch origin
        git checkout v1.2.0
        binaries_120
        echo y |./byfn.sh upgrade -i 1.2.0
        copy_logs $? default-channel
        echo
