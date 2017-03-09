#!/bin/bash -eu
set -o pipefail

# Run end-to-end (CLI) Tests
######################

cd ${WORKSPACE}/gopath/src/github.com/hyperledger/fabric/examples/e2e_cli
docker rm -f $(docker ps -aq) || true
./generateCfgTrx.sh && docker-compose up >> dockerlogfile.log 2>&1 &
sleep 40 && docker ps -a && docker logs -f cli | tee results.log && docker-compose down

grep -q "All GOOD, End-2-End execution completed " results.log
  if [ $? -ne 0 ]; then
      echo "=============E2E TEST FAILED========="
      exit 1
      else
      echo "=============E2E TEST PASSED=========="

fi

