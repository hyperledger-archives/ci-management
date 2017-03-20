#!/bin/bash

set -o pipefail

CA_TAG=$(docker inspect --format "{{ .RepoTags }}" hyperledger/fabric-ca | sed 's/.*:\(.*\)]/\1/')

NEXUS_URL=nexus3.hyperledger.org:10003
ORG_NAME="hyperledger/fabric"

dockerCaPush() {
  docker push $NEXUS_URL/$ORG_NAME-ca:$CA_TAG
  echo
  echo "==> $NEXUS_URL/$ORG_NAME-ca:$CA_TAG"
}
dockerCaPush
