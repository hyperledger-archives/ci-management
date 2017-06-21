#!/bin/bash

# vim: sw=4 ts=4 sts=4 et :

# change to the script location dir and make sure everything is executable
cd "${0%/*}" || exit
chmod +x ./*.sh

# Determine our system type
./system_type.sh

source /tmp/system_type.sh
./ssh_settings.sh
#./"${SYSTEM_TYPE}.sh"

# Create Jenkins User and allow Jenkins to connect
./create_jenkins_user.sh

# Init has now completed
touch /tmp/init_finished
