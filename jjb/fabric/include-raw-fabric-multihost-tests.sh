#!/bin/bash
set -o pipefail

# Remove the repositories
rm -rf fabric-test

# clone fabric-test repository
git clone https://github.com/hyperledger/fabric-test.git

cd fabric-test && git submodule update --init --recursive
cat ../clouds.yaml tools/ATD/vars/lfos.yml > cello/src/agent/ansible/vars/lfos.yml
cp tools/ATD/vars/ptenetwork.yml cello/src/agent/ansible/vars/bc1st.yml
cp -r tools/ATD/vars/roles/* cello/src/agent/ansible/roles

chmod 400 ../fd*

# shellcheck disable=SC2046
eval $(ssh-agent -s) 2>/dev/null && ssh-add ../fd

cd cello/src/agent/ansible || exit
mkdir -p run

# destory cluster before intialize the cluster setup
ansible-playbook -e "mode=destroy cloud_type=os env=lfos" provcluster.yml
ansible-playbook -e "mode=apply cloud_type=os env=lfos" provcluster.yml
ansible-playbook -i run/runhosts -e "mode=apply env=lfos env_type=flanneld" initcluster.yml
ansible-playbook -i run/runhosts -e "mode=apply env=bc1st target=docker,configtxgen,cryptogen" setupfabric.yml
ansible-playbook -i run/runhosts -e "mode=apply env=bc1st" verify.yml

cd $WORKSPACE/fabric-test/tools/ATD/ || exit

# execute FAB-3989-4i-TLS test case
ansible-playbook -i ../../cello/src/agent/ansible/run/runhosts \
  --extra-vars "chaincode=samplecc testcase=FAB-3989-4i-TLS" -e "mode=apply env=bc1st tool_type=pte" ptesetup.yml --skip-tags="code,make"

# here we add invocation steps to start test playbooks
ansible-playbook -i ../../cello/src/agent/ansible/run/runhosts \
  --extra-vars "chaincode=samplecc testcase=FAB-3989-4i-TLS" -e "mode=destroy env=bc1st tool_type=pte" ptesetup.yml --skip-tags="cleanfabric"

cp -r /tmp/*.tgz $WORKSPACE
cd $WORKSPACE || exit
tar -xvzf *.tgz
