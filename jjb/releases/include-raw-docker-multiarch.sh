#!/bin/bash -e

# Clone fabric git repository
clone_Repo() {
  rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/$PROJECT
  WD="${WORKSPACE}/gopath/src/github.com/hyperledger/$PROJECT"
  REPO_NAME=$1
  git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
  cd $WD && git checkout $GERRIT_BRANCH && git checkout $RELEASE_COMMIT
  # Checkout to the branch and checkout to release commit
  # Provide the value to release commit from Jenkins parameter
  echo "-------> INFO: RELEASE_COMMIT" $RELEASE_COMMIT
}

export_Go() {
  # Fetch Go Version from fabric ci.properties file
  GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
  export GO_VER
  OS_VER=$(dpkg --print-architecture)
  echo "------> OS_VER" $OS_VER
  export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
  export PATH=$GOROOT/bin:$PATH
  echo "------> GO_VER" $GO_VER
  ARCH=$(go env GOARCH)
  echo "------> ARCH" $ARCH
}

# Build fabric images
publish_Multiarch() {

  # Remove manifest-tool
  rm -rf github.com/estesp/manifest-tool
  # Install manifest-tool
  go get github.com/estesp/manifest-tool
  go install github.com/estesp/manifest-tool
  cd $WD/scripts
  BASE_VERSION=$PUSH_VERSION ./multiarch.sh $DOCKER_HUB_USERNAME $DOCKER_HUB_PASSWORD
}

# Clone repository
clone_Repo $PROJECT
# Export GOPATH
export_Go
# Login to hyperledger dockerhub account
docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
# Publish Multiarch tags to dockerhub
publish_Multiarch
