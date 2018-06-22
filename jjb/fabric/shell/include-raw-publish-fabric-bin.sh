#!/bin/bash -e

############################################
# Pull "1.2.0-stable" docker images from nexus3
# Tag it as $ARCH-$RELEASE_VERSION (1.2.0)
# Push tagged images to hyperledger dockerhub
#############################################

STABLE_VERSION=1.2.0-stable
export STABLE_VERSION
ARCH=$(go env GOARCH)
if [ "$ARCH" = "amd64" ]; then
	ARCH=amd64
else
    ARCH=$(uname -m)
fi

cd $GOPATH/src/github.com/hyperledger/fabric
# pull fabric binaries
pull_Binary() {
#    MARCH=$(echo "$(uname -s|tr '[:upper:]' '[:lower:]'|sed 's/mingw64_nt.*/windows/')-$(uname -m | sed 's/x86_64/amd64/g')" | awk '{print tolower($0)}')
#    export MARCH
#    echo "------> MARCH:" $MARCH
#    MVN_METADATA=$(echo "https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-stable/maven-metadata.xml")
#    curl -L "$MVN_METADATA" > maven-metadata.xml
#    RELEASE_TAG=$(cat maven-metadata.xml | grep release)
    COMMIT=f6e72eb
#    COMMIT=$(echo $RELEASE_TAG | awk -F - '{ print $4 }' | cut -d "<" -f1)
    echo "--------> COMMIT:" $COMMIT

# pull binaries and tag it as version
    for binary in linux-amd64 windows-amd64 darwin-amd64 linux-ppc64le linux-s390x; do
	mkdir -p release/$binary && cd release/$binary
    	curl https://nexus.hyperledger.org/content/repositories/releases/org/hyperledger/fabric/hyperledger-fabric-stable/$binary.$STABLE_VERSION-$COMMIT/hyperledger-fabric-stable-$binary.$STABLE_VERSION-$COMMIT.tar.gz | tar xz
    	rm -rf hyperledger-fabric-* && tar -czf hyperledger-fabric-$binary.$1.tar.gz *
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
        cd $GOPATH/src/github.com/hyperledger/fabric
    done
        echo "========> DONE <======="
}

# Push Release
pull_Binary $PUSH_VERSION

