#!/bin/bash -ex

# Clone git repository
clone_Repo() {
  rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/$PROJECT
  WD="${WORKSPACE}/gopath/src/github.com/hyperledger/$PROJECT"
  REPO_NAME=$1
  git clone --single-branch -b $GERRIT_BRANCH https://github.com/hyperledger/$REPO_NAME $WD
  cd $WD && git checkout $GERRIT_BRANCH && git checkout $RELEASE_COMMIT
  # Checkout to the branch and checkout to release commit
  # Provide the value to release commit from Jenkins parameter
  echo "-------> INFO: RELEASE_COMMIT" $RELEASE_COMMIT
}

export_Go() {
  # Fetch Go Version from fabric ci.properties file
  if [ ! -e ci.properties ]; then
     curl -L https://raw.githubusercontent.com/hyperledger/fabric-baseimage/master/scripts/common/setup.sh > setup.sh
     GO_VER=$(cat setup.sh | grep GO_VER= | cut -d "=" -f 2)
     export GO_VER
     echo "-------> GO_VER" $GO_VER
  else
     GO_VER=$(cat ci.properties | grep GO_VER | cut -d "=" -f 2)
     export GO_VER
     echo "-------> GO_VER" $GO_VER
  fi
  OS_VER=$(dpkg --print-architecture)
  echo "------> OS_VER" $OS_VER
  export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
  export PATH=$GOROOT/bin:$PATH
}

# Build fabric images
publish_Multiarch() {

  # Install manifest-tool
  mkdir -p "${GOPATH}/bin"
  wget -q https://github.com/estesp/manifest-tool/releases/download/v1.0.0/manifest-tool-linux-amd64
  mv manifest-tool-linux-amd64 "${GOPATH}/bin/manifest-tool"
  chmod +x "${GOPATH}/bin/manifest-tool"

  cd $WD/scripts
  BASE_VERSION=$PUSH_VERSION TWO_DIGIT_VERSION=$TWO_DIGIT_VERSION ./multiarch.sh $DOCKER_HUB_USERNAME $DOCKER_HUB_PASSWORD
  cd -
}

# Clone repository
clone_Repo $PROJECT
# Export GOPATH
export_Go
# Login to hyperledger dockerhub account
docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD
# Publish Multiarch tags to dockerhub
publish_Multiarch
