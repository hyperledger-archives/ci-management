#!/bin/bash -eu

ORG_NAME="hyperledger/fabric"

docker login --username=$DOCKER_HUB_USERNAME --password=$DOCKER_HUB_PASSWORD

# Clone fabric git repository
clone_Fabric() {
 rm -rf ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric
 WD="${WORKSPACE}/gopath/src/github.com/hyperledger/fabric"
 REPO_NAME=fabric
 git clone --single-branch -b $GERRIT_BRANCH https://github.com/hyperledger/$REPO_NAME $WD
 cd $WD && git checkout $GERRIT_BRANCH && git checkout $RELEASE_COMMIT
 # Checkout to the branch and checkout to release commit
 # Provide the value to release commit from Jenkins parameter
 echo "-------> INFO: RELEASE_COMMIT" $RELEASE_COMMIT
}

# Build fabric images
docker_Build_Images() {
     # build docker images
     make docker
}

docker_Fabric_Push() {
   # Clone fabric
   clone_Fabric
   # export go
   if [ "$GERRIT_BRANCH" = "release-1.0" ] || [ "$GERRIT_BRANCH" = "release-1.1" ]; then
         ARCH=x86_64
         export ARCH
         echo "----------> ARCH:" $ARCH
   else
         ARCH=$(dpkg --print-architecture) # amd64, s390x
         export ARCH
         echo "----------> ARCH:" $ARCH
   fi
   # Call to build fabric images
   docker_Build_Images
   # shellcheck disable=SC2043
   echo "#########################"
   echo -e "\033[1m P U B L I S H - F A B R I C\033[0m"
   echo "#########################"
   echo
   for IMAGES in ${IMAGES_LIST[*]}; do
       # Tag :latest to :release version ($PUSH_VERSION)
       docker tag $ORG_NAME-$IMAGES $ORG_NAME-$IMAGES:$ARCH-$1
       echo -e "\033[1m==> $IMAGES\033[0m"
       docker push $ORG_NAME-$IMAGES:$ARCH-$1
       echo
       echo "==> $ORG_NAME-$IMAGES:$ARCH-$1"
       echo
  done
}

# list docker images
docker images | grep hyperledger

if [[ "$GERRIT_BRANCH" = "release-1.0" ]]; then
    # Images list
    IMAGES_LIST=(peer orderer ccenv tools zookeeper kafka couchdb javaenv)
    # Push Fabric Docker Images to hyperledger dockerhub Repository
    docker_Fabric_Push $PUSH_VERSION
elif [[ "$GERRIT_BRANCH" = "release-1.1" ]]; then
   # Images list
   IMAGES_LIST=(peer orderer ccenv tools javaenv)
   # Push Fabric Docker Images to hyperledger dockerhub Repository
   docker_Fabric_Push $PUSH_VERSION
elif [[ "$GERRIT_BRANCH" = "master" ]]; then
   # Images list
   IMAGES_LIST=(baseos peer orderer ccenv tools)
   # Push Fabric Docker Images to hyperledger dockerhub Repository
   docker_Fabric_Push $PUSH_VERSION
else
    # Images list
    IMAGES_LIST=(peer orderer ccenv tools)
    # Push Fabric Docker Images to hyperledger dockerhub Repository
    docker_Fabric_Push $PUSH_VERSION
fi

publish_Binary() {
   # PUSH_VERSION refer value from jenkins parameter
   make release-clean dist-clean dist-all PROJECT_VERSION=$1
     for binary in ${PLATFORM_LIST[*]}; do
       cd $WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/$binary
       echo "Pushing hyperledger-fabric-$binary.$1.tar.gz to maven releases.."
       mvn org.apache.maven.plugins:maven-deploy-plugin:deploy-file \
        -Dfile=$WORKSPACE/gopath/src/github.com/hyperledger/fabric/release/$binary/hyperledger-fabric-$binary.$1.tar.gz \
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

if [[ "$ARCH" = "amd64" ]]; then
   if [ "$GERRIT_BRANCH" = "release-1.0" ] || [ "$GERRIT_BRANCH" = "release-1.1" ]; then
       # platform list
       PLATFORM_LIST=(linux-amd64 windows-amd64 darwin-amd64 linux-s390x linux-ppc64le)
       echo "#########################"
       echo -e "\033[1m P U B L I S H - F A B R I C - B I N A R I E S\033[0m"
       echo "#########################"
       echo
       publish_Binary $PUSH_VERSION
       echo "------> Publishing binaries from $GERRIT_BRANCH"
   else
       # platform list
       PLATFORM_LIST=(linux-amd64 windows-amd64 darwin-amd64 linux-s390x)
       publish_Binary $PUSH_VERSION
       # Provide value to PUSH_VERSION from Jenkins parameter.
   fi
else
    echo -e "\033[1m=====> Dont publish binaries from $ARCH\033[0m"
fi
