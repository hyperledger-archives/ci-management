#!/bin/bash -eux

# Clone git repository
clone_repo() {
    rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/$PROJECT
    wd="${WORKSPACE}/gopath/src/github.com/hyperledger/$PROJECT"
    REPO_NAME=$1
    git clone --single-branch -b $GERRIT_BRANCH https://github.com/hyperledger/$REPO_NAME $wd
    cd $wd
    git checkout $GERRIT_BRANCH
    git checkout $RELEASE_COMMIT
    # Checkout to the branch and checkout to release commit
    # Provide the value to release commit from Jenkins parameter
    echo "-------> INFO: RELEASE_COMMIT" $RELEASE_COMMIT
}

export_go() {
    # Fetch Go Version from fabric ci.properties file
    if [ ! -e ci.properties ]; then
        curl -L https://raw.githubusercontent.com/hyperledger/fabric-baseimage/master/scripts/common/setup.sh \
           > setup.sh
        go_ver=$(cat setup.sh | grep go_ver= | cut -d "=" -f 2)
        echo "-------> go_ver" $go_ver
    else
        go_ver=$(cat ci.properties | grep go_ver | cut -d "=" -f 2)
        echo "-------> go_ver" $go_ver
    fi
    os_ver=$(dpkg --print-architecture)
    echo "------> os_ver" $os_ver
    goroot=/opt/go/go$go_ver.linux.$os_ver
    export PATH=$goroot/bin:$PATH
}

# Build $PROJECT multiarch images
publish_multiarch() {
    # Remove manifest-tool
    rm -rf github.com/estesp/manifest-tool
    # Install manifest-tool
    GOROOT=$goroot go get github.com/estesp/manifest-tool
    GOROOT=$goroot go install github.com/estesp/manifest-tool
    cd $wd/scripts
    NS_PULL=nexus3.hyperledger.org:10001/hyperledger NS_PUSH=nexus3.hyperledger.org:10002/hyperledger \
      BASE_VERSION=$PUSH_VERSION TWO_DIGIT_VERSION=$TWO_DIGIT_VERSION ./multiarch.sh
    cd -
}

# Clone repository
clone_repo $PROJECT
# Export GOPATH
export_go
# Publish Multiarch tags to dockerhub
publish_multiarch
