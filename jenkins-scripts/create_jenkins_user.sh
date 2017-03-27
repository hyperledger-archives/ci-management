#!/bin/bash

# vim: sw=4 ts=4 sts=4 et :

#######################
# Create Jenkins User #
#######################

OS=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')

useradd -m -G docker -s /bin/bash jenkins
mkdir /home/jenkins/.ssh
mkdir /w
echo #######################
echo # EMIT CONTENTS OF /home/$os/.ssh/authorized_keys
echo #######################
cat /home/$os/.ssh/authorized_keys
echo #######################
echo # EMITTED CONTENTS OF /home/$os/.ssh/authorized_keys
echo #######################
while [ `wc -l<"/home/${OS}/.ssh/authorized_keys"` -lt 2 ]
do
  echo Not enough keys.
  sleep 5
done
echo #######################
echo # EMIT CONTENTS OF /home/$os/.ssh/authorized_keys
echo #######################
cat /home/$os/.ssh/authorized_keys
echo #######################
echo # EMITTED CONTENTS OF /home/$os/.ssh/authorized_keys
echo #######################
cp -r "/home/${OS}/.ssh/authorized_keys" /home/jenkins/.ssh/authorized_keys
echo #######################
echo # EMIT CONTENTS OF /home/jenkins/.ssh/authorized_keys
echo #######################
cat /home/jenkins/.ssh/authorized_keys
echo #######################
echo # EMITTED CONTENTS OF /home/jenkins/.ssh/authorized_keys
echo #######################
# Generate ssh key for use by Robot jobs
echo -e 'y\n' | ssh-keygen -N "" -f /home/jenkins/.ssh/id_rsa -t rsa
chown -R jenkins:jenkins /home/jenkins/.ssh /w

# Own variable hyperledger data
chown -R jenkins:jenkins /var/hyperledger
