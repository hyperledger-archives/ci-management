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
    echo "DOCKER_OPTS=\"-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock\"" > /etc/default/docker
    service docker start
}

deb_docker_pull_baseimage() {
    echo "---> Pulling Fabric Baseimage"
    docker pull hyperledger/fabric-baseimage:x86_64-0.0.10
}

deb_create_hyperledger_vardir() {
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
    PACKAGES="g++-4.8 build-essential"

    # Libraries
    PACKAGES="$PACKAGES libsnappy-dev zlib1g-dev libbz2-dev \
        python-dev libyaml-dev python-pip"

    # Tcl prerequisites for busywork
    PACKAGES="$PACKAGES tcl tclx tcllib"

    # Docker
    PACKAGES="$PACKAGES apparmor \
        linux-image-extra-$(uname -r) docker-engine=1.8.2-0~trusty"

    # Go Lang
    PACKAGES="$PACKAGES golang-1.6"

    echo '---> Installing packages'
    apt-get -qq install -y $PACKAGES
}

deb_add_docker_repo() {
    echo '---> Installing the Docker Repo'
    apt-key adv \
      --keyserver hkp://p80.pool.sks-keyservers.net:80 \
      --recv-keys 58118E89F3A912897C070ADBF76221572C52609D
    echo "deb https://apt.dockerproject.org/repo ubuntu-trusty main" > /etc/apt/sources.list.d/docker.list
}

deb_install_docker_compose() {
    echo '---> Installing Docker Compose'
    curl -L "https://github.com/docker/compose/releases/download/1.5.2/docker-compose-`uname -s`-`uname -m`" > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
}

deb_install_pip_pkgs() {
    PIP_PACKAGES="behave nose"
    PIP_VERSIONED_PACKAGES="flask==0.10.1 \
        python-dateutil==2.2 pytz==2014.3 pyyaml==3.10 couchdb==1.0 \
        flask-cors==2.0.1 requests==2.4.3"

    echo '---> Installing Pip Packages'
    pip install -U pip
    pip install $PIP_PACKAGES
    pip install -I $PIP_VERSIONED_PACKAGES
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

    deb_create_hyperledger_vardir
    deb_add_docker_repo
    deb_add_apt_ppa 'ppa:ubuntu-toolchain-r/test'
    deb_install_pkgs
    deb_install_docker_compose
    deb_install_pip_pkgs
    deb_install_go
    deb_install_rocksdb
    deb_update_alternatives
    deb_configure_docker
    deb_docker_pull_baseimage

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
