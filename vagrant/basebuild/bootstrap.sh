#!/bin/bash

# vim: sw=4 ts=4 sts=4 et tw=72 :

rh_systems() {
    echo "---> No extra steps presently for ${FACTER_OS}"
}

ubuntu_systems() {
    # Ensure that necessary variables are set to enable noninteractive
    # mode in commands.
    export DEBIAN_FRONTEND=noninteractive
    echo "---> No extra steps presently for ${FACTER_OS}"
}

# Determine our OS so we can do distro specific tasks
# NOTE: puppet is installed with our baselining
FACTER_OS=$(facter operatingsystem)

echo "---> Executing ${FACTER_OS} system bootstrapping"
case "${FACTER_OS}" in
    Fedora|CentOS|RedHat)
        rh_systems
    ;;
    Ubuntu)
        ubuntu_systems
    ;;
    *)
        echo "---> ${FACTER_OS} is not presently handled"
    ;;
esac
