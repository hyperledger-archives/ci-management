#!/bin/bash

# vim: sw=4 ts=4 sts=4 et :

# change to the script location dir and make sure everything is executable
cd "${0%/*}"
chmod +x ./*.sh

# Determine our system type
./system_type.sh

source /tmp/system_type.sh
./ssh_settings.sh
./create_jenkins_user.sh
./"${SYSTEM_TYPE}.sh"
