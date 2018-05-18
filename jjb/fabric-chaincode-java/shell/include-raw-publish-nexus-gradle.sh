#!/bin/bash -exu
set -o pipefail
# gladlew build from fabric-chaincode-java repo
./gradlew build
#./gradlew :shim:publishShimJarPublicationToHyperledgerNexusSnapshotRepository
./gradlew -Pmaven.settings.location=${MAVEN_SETTINGS_LOCATION} :fabric-chaincode-shim:publishShimJarPublicationToHyperledger-snapshotsRepository
