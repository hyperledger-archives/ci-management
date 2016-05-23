#!/bin/bash

# vim: sw=4 ts=4 sts=4 et :

#######################
# Create Jenkins User #
#######################

OS=$(facter operatingsystem | tr '[:upper:]' '[:lower:]')

useradd -m -s /bin/bash jenkins
mkdir /home/jenkins/.ssh
mkdir /w
cp -r "/home/${OS}/.ssh/authorized_keys" /home/jenkins/.ssh/authorized_keys
# Generate ssh key for use by Robot jobs
echo -e 'y\n' | ssh-keygen -N "" -f /home/jenkins/.ssh/id_rsa -t rsa
chown -R jenkins:jenkins /home/jenkins/.ssh /w
