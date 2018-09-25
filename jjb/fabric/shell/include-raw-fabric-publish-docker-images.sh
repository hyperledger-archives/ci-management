#!/bin/bash -e

ORG_NAME="hyperledger/fabric"

docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD

# Clone fabric git repository
clone_Fabric() {

 rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric
 WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
 REPO_NAME=fabric
 git clone git://cloud.hyperledger.org/mirror/$REPO_NAME $WD
 cd $WD && git checkout $GERRIT_BRANCH && git checkout $RELEASE_COMMIT
 echo "-------> INFO: RELEASE_COMMIT" $RELEASE_COMMIT
 # Fetch Go Version from fabric ci.properties file
 GO_VER=`cat ci.properties | grep GO_VER | cut -d "=" -f 2`
 export GO_VER
 OS_VER=$(dpkg --print-architecture)
 echo "------> ARCH: $OS_VER"
 export GOROOT=/opt/go/go$GO_VER.linux.$OS_VER
 export PATH=$GOROOT/bin:$PATH
 echo "------> GO_VER" $GO_VER
 ARCH=$(go env GOARCH)
 echo "------> ARCH" $ARCH
}

# Build fabric images
docker_Build_Images() {
     # build docker images
     make docker
     if [ $? != 0 ]; then
       echo "-------> ERROR: make $IMAGES failed"
       exit 1
     fi
}

# list all docker images
docker images | grep hyperledger

docker_Fabric_Push() {
   # Clone fabric
   clone_Fabric
   # Call to build fabric images
   docker_Build_Images
  # shellcheck disable=SC2043
  for IMAGES in peer orderer ccenv tools; do
    echo "==> $IMAGES"
    # tag latest to release version
    docker tag $ORG_NAME-$IMAGES $ORG_NAME-$IMAGES:$ARCH-$1
    # Push images to dockerhub
    docker push $ORG_NAME-$IMAGES:$ARCH-$1
    echo
    echo "==> $ORG_NAME-$IMAGES:$ARCH-$1"
    echo
  done
}

publish_Binary() {

   make release-clean dist-clean && make dist-all PROJECT_VERSION=$1

     for binary in linux-amd64 windows-amd64 darwin-amd64 linux-s390x; do
       echo "Pushing hyperledger-fabric-$binary.$1.tar.gz to maven releases.."
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/$binary/hyperledger-fabric-$binary.$1.tar.gz * \
        -DrepositoryId=hyperledger-releases \
        -Durl=https://nexus.hyperledger.org/content/repositories/releases/ \
        -DgroupId=org.hyperledger.fabric \
        -Dversion=$binary-$1 \
        -DartifactId=hyperledger-fabric \
        -DgeneratePom=true \
        -DuniqueVersion=false \
        -Dpackaging=tar.gz \
        -gs $GLOBAL_SETTINGS_FILE -s $SETTINGS_FILE
   done
     echo "========> DONE <======="
}

docker_Fabric_Push $PUSH_VERSION
if [ "$ARCH" = "amd64" ]; then
     publish_Binary $PUSH_VERSION
else
    echo "========> Dont publish binaries froms 390x"
fi
