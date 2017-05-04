#!/bin/bash -eu
set -o pipefail

# Run end-to-end (CLI) Tests
######################

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/examples/e2e_cli
# wait for 10 sec's before exit
./network_setup.sh restart mychannel 10
docker ps -a && docker logs -f cli | tee results.log && ./network_setup.sh down

grep -q "All GOOD, End-2-End execution completed " results.log
  if [ $? -ne 0 ]; then
      echo "=============E2E TEST FAILED========="
      exit 1
      else
      echo "=============E2E TEST PASSED=========="

fi
