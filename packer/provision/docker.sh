#!/bin/bash

# vim: sw=4 ts=4 sts=4 et :

add_jenkins_user() {
    git clone https://gerrit.hyperledger.org/r/ci-management.git /ci-management
    /ci-management/jenkins-scripts/init_system.sh
}

rh_changes() {
    echo "---> RH changes"
    # Following directions from
    # https://docs.docker.com/engine/installation/linux/docker-ce/centos/

    # remove old docker
    yum remove -y docker docker-common docker-selinux docker-engine

    # set up the repository
    yum install -y yum-utils device-mapper-persistent-data lvm2
    yum-config-manager --add-repo \
    https://download.docker.com/linux/centos/docker-ce.repo
    yum clean -y metadata

    # install docker and enable it
    echo "---> Installing docker"
    yum install -y docker-ce supervisor bridge-utils
    systemctl enable docker

    # configure docker networking so that it does not conflict with LF
    # internal networks
    cat <<EOL > /etc/sysconfig/docker-network
# /etc/sysconfig/docker-network
DOCKER_NETWORK_OPTIONS='--bip=10.250.0.254/24'
EOL
    # configure docker daemon to listen on port 5555 enabling remote
    # managment
    mkdir /etc/docker
    touch /etc/docker/daemon.json
    cat <<EOL > /etc/docker/daemon.json
{
"selinux-enabled": true,
"hosts": ["unix:///var/run/docker.sock", "tcp://0.0.0.0:5555"]
}
EOL

    # Install python dependencies
    yum install -y python-{devel,virtualenv,setuptools,pip}
}

deb_docker_fix(){
    echo "---> Fixing docker"
    systemctl stop docker
    cat <<EOL > /etc/systemd/system/docker.service
[Unit]
Description=Docker Application Container Engine
Documentation=https://docs.docker.com
After=network.target docker.socket
Requires=docker.socket

[Service]
Type=notify
# the default is not to use systemd for cgroups because the delegate issues still
# exists and systemd currently does not support the cgroup feature set required
# for containers run by docker
ExecStart=
ExecStart=/usr/bin/dockerd --mtu 1392 -H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock
ExecReload=/bin/kill -s HUP $MAINPID
# Having non-zero Limit*s causes performance problems due to accounting overhead
# in the kernel. We recommend using cgroups to do container-local accounting.
LimitNOFILE=infinity
LimitNPROC=infinity
LimitCORE=infinity
# Uncomment TasksMax if your systemd version supports it.
# Only systemd 226 and above support this version.
TasksMax=infinity
TimeoutStartSec=0
# set delegate yes so that systemd does not reset the cgroups of docker containers
Delegate=yes
# kill only the docker process, not all processes in the cgroup
KillMode=process

[Install]
WantedBy=multi-user.target
EOL
    systemctl start docker
    echo "---> Check the MTU here"
    docker network inspect bridge
    echo "---> MTU should be 1392"
}

deb_install_go() {
    echo "---> Installing Go"

    curl -sL -o /usr/local/bin/gimme https://raw.githubusercontent.com/travis-ci/gimme/master/gimme
    chmod +x /usr/local/bin/gimme

    gimme 1.7 /opt/go
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

    cd /tmp/rocksdb || exit
    make shared_lib
    INSTALL_PATH='/usr/local' make install-shared
    ldconfig
}

deb_add_docker_repo() {
    # Following directions from
    # https://docs.docker.com/engine/installation/linux/docker-ce/ubuntu/

    # remove old docker
    sudo apt-get remove -y docker docker-engine docker.io

    # set up the repository
    echo '---> Installing the Docker Repo'
    sudo apt-get update
    sudo apt-get install \
    apt-transport-https \
    ca-certificates \
    curl \
    software-properties-common
    curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
    sudo add-apt-repository \
    "deb [arch=amd64] https://download.docker.com/linux/ubuntu \
    $(lsb_release -cs) \
    stable"

    # install docker and enable it
    sudo apt-get update
    sudo apt-get install -y docker-ce
}

deb_install_docker_compose() {
    echo '---> Installing Docker Compose'
    curl -sL "https://github.com/docker/compose/releases/download/1.16.1/docker-compose-`uname -s`-`uname -m`" > /usr/local/bin/docker-compose
    chmod +x /usr/local/bin/docker-compose
    docker-compose --version
}

deb_install_pip_pkgs() {
    PIP_PACKAGE_DEPS="urllib3 pyopenssl ndg-httpsclient pyasn1 ecdsa python-slugify grpcio-tools"
    PIP_PACKAGES="behave nose"
    GRPC_PACKAGES="grpcio==1.0.4"
    JINJA2_PACKAGES="jinja2"
    B3J0F_PACKAGES="b3j0f.aop"
    PIP_VERSIONED_PACKAGES="flask==0.10.1 \
        python-dateutil==2.2 pytz==2014.3 pyyaml==3.10 couchdb==1.0 \
        flask-cors==2.0.1 requests==2.12.1 pysha3==1.0b1"

    echo '---> Installing Pip Packages'
    pip3 install -U pip
    pip3 install $PIP_PACKAGE_DEPS
    pip3 install $PIP_PACKAGES
    pip3 install -I $PIP_VERSIONED_PACKAGES
    pip3 install -U $GRPC_PACKAGES $JINJA2_PACKAGES $B3J0F_PACKAGES
}

deb_update_alternatives() {
    echo '---> Updating Alternatives'
    update-alternatives --install /usr/bin/g++ g++ /usr/bin/g++-4.8 90
}

deb_install_python() {
    # Python install
    echo python install
    PACKAGES="python3-venv python3-pip python2.7-dev python-virtualenv python-setuptools python-pip python-xmlrunner python-pytest"
    apt-get -qq install -y $PACKAGES
}

deb_install_softhsm() {
    apt-get -qq install -y softhsm2

    # Create tokens directory
    mkdir -p /var/lib/softhsm/tokens/

    #Initialize token
    softhsm2-util --init-token --slot 0 --label "ForFabric" --so-pin 1234 --pin 98765432

    # Add jenkins user to softhsm group
    chown -R jenkins:jenkins /var/lib/softhsm /etc/softhsm
}

deb_install_node() {
    # Node install
    pushd /usr/local
    nvm install 8.4.0
    nvm install 7.4.0
    nvm ls
    popd
    echo "npm -v: `npm -v`"
    echo "node -v: `node -v`"
}

deb_install_nvm() {
    # Install nvm
    echo "----> nvm install"
    apt-get update
    apt-get install build-essential
    wget -qO- https://raw.githubusercontent.com/creationix/nvm/v0.31.0/install.sh | bash
    export NVM_DIR="$HOME/.nvm"
    # shellcheck source=/dev/null
    [ -s "$NVM_DIR/nvm.sh" ] && . "$NVM_DIR/nvm.sh" # This loads nvm
    command -v nvm
}

deb_install_pkgs() {
    # Compiling Essentials
    PACKAGES="g++-4.8 build-essential software-properties-common curl sudo zip libtool"

    # Libraries
    PACKAGES="$PACKAGES libsnappy-dev zlib1g-dev libbz2-dev \
        libffi-dev libssl-dev python-dev libyaml-dev python-pip"

    # Packages for IBM fvt
    PACKAGES="$PACKAGES haproxy haproxy-doc htop html2text isag jq \
        libdbd-pg-perl locales-all mysql-client mysql-common \
        mysql-server postgresql postgresql-contrib \
        postgresql-doc vim-haproxy zsh"

    # Tox for py-sdk
    PACKAGES="$PACKAGES tox"

    # maven for sdk-java
    PACKAGES="$PACKAGES maven"

    # Tcl prerequisites for busywork
    PACKAGES="$PACKAGES tcl tclx tcllib"

    # Docker
    PACKAGES="$PACKAGES apparmor \
        linux-image-extra-$(uname -r) docker-engine"

    echo '---> Installing packages'
    apt-get -qq install -y $PACKAGES
    docker --version
}

deb_add_apt_ppa() {
    echo '---> Adding Ubuntu PPAs'
    add-apt-repository -y "$@"
    apt-get -qq update
}

ubuntu_changes() {
    echo "---> Ubuntu changes"
    export DEBIAN_FRONTEND=noninteractive

    deb_install_go
    deb_create_hyperledger_vardir
    deb_add_docker_repo
    deb_add_apt_ppa 'ppa:ubuntu-toolchain-r/test'
    deb_install_pkgs
    deb_install_python
    deb_install_pip_pkgs
    add_jenkins_user
    deb_install_docker_compose
    deb_install_nvm
    deb_install_node
    deb_install_softhsm
    deb_install_rocksdb
    deb_update_alternatives
    deb_docker_pull_baseimage
    deb_docker_fix

    echo "---> No extra steps presently for ${FACTER_OS}"
}

OS=$(/usr/bin/facter operatingsystem)
case "$OS" in
    CentOS|Fedora|RedHat)
        rh_changes
    ;;
    Ubuntu)
        ubuntu_changes
    ;;
    *)
        echo "${OS} has no configuration changes"
    ;;
esac
