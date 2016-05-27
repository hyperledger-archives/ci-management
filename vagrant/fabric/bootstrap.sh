#!/bin/bash

# vim: sw=4 ts=4 sts=4 et tw=72 :

deb_install_go() {
    echo "---> Installing Go"

    curl -sL -o /usr/local/bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
    chmod +x /usr/local/bin/gimme

    gimme 1.6 /opt/go
}

deb_configure_docker() {
    echo "---> Configuring Docker"
    service docker stop
    echo "DOCKER_OPS=\"-H tcp://0.0.0.0:2735 -H unix:///var/run/docker.sock\"" > /etc/default/docker
    service docker start
}

deb_hyperledger_clean() {
    echo "---> Creating Hyperledger Vardir"
    mkdir /var/hyperledger/
    chown $USER:$USER /var/hyperledger
}

deb_install_rocksdb() {
    #cd scripts/provision/ && chmod +x host.sh && sudo ./host.sh
    echo "---> Installing RocksDB"

    git clone --branch v4.1 \
        --single-branch \
        --depth 1 \
        https://github.com/facebook/rocksdb.git /tmp/rocksdb

    cd /tmp/rocksdb
    make shared_lib
    INSTALL_PATH='/usr/local' make install-shared
    ldconfig
}

deb_install_pkgs() {
    # Compiling Essentials
    PACKAGES="g++-4.8"
    PACKAGES="$PACKAGES build-essential"

    # Libraries
    PACKAGES="$PACKAGES libsnappy-dev zlib1g-dev libbz2-dev"

    # Go Lang
    PACKAGES="$PACKAGES golang-1.6"

    # Docker
    PACKAGES="$PACKAGES docker.io"

    echo '---> Installing packages'
    apt-get -qq install -y $PACKAGES
}

deb_update_alternatives() {
    echo '---> Updating Alternatives'
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 90
}

deb_add_apt_ppa() {
    echo '---> Adding Ubuntu PPAs'
    add-apt-repository -y $@
    apt-get -qq update
}

rh_systems() {
    echo "---> No extra steps presently for ${FACTER_OS}"
}

ubuntu_systems() {
    # Ensure that necessary variables are set to enable noninteractive
    # mode in commands.
    export DEBIAN_FRONTEND=noninteractive

    deb_hyperledger_clean
    deb_add_apt_ppa 'ppa:ubuntu-toolchain-r/test'
    deb_install_pkgs
    deb_install_go
    deb_install_rocksdb
    deb_update_alternatives
    deb_configure_docker

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
