#!/bin/bash -ue

# vim: ts=4 sw=4 sts=4 et tw=72 :

ensure_ubuntu_install() {
    # Workaround for mirrors occassionally failing to install a package.
    # On Ubuntu sometimes the mirrors fail to install a package. This wrapper
    # checks that a package is successfully installed before moving on.

   for pkg in "$@";
    do
        # Retry installing package 5 times if necessary
        # shellcheck disable=SC2034
        for i in {0..5}
        do
            while pgrep apt > /dev/null; do sleep 1; done
            if [ "$(dpkg-query -W -f='${Status}' "$pkg" 2>/dev/null | grep -c "ok installed")" -eq 0 ]; then
                apt-cache policy "$pkg"
                apt-get install "$pkg"
                continue
            else
                echo "$pkg already installed."
                break
            fi
        done
    done
}

rh_systems() {
    # Handle the occurance where SELINUX is actually disabled
    SELINUX=$(grep -E '^SELINUX=(disabled|permissive|enforcing)$' /etc/selinux/config)
    MODE=$(echo "$SELINUX" | cut -f 2 -d '=')
    case "$MODE" in
        permissive)
            echo "************************************"
            echo "** SYSTEM ENTERING ENFORCING MODE **"
            echo "************************************"
            # make sure that the filesystem is properly labelled.
            # it could be not fully labeled correctly if it was just switched
            # from disabled, the autorelabel misses some things
            # skip relabelling on /dev as it will generally throw errors
            restorecon -R -e /dev /

            # enable enforcing mode from the very start
            setenforce enforcing

            # configure system for enforcing mode on next boot
            sed -i 's/SELINUX=permissive/SELINUX=enforcing/' /etc/selinux/config
        ;;
        disabled)
            sed -i 's/SELINUX=disabled/SELINUX=permissive/' /etc/selinux/config
            touch /.autorelabel

            echo "*******************************************"
            echo "** SYSTEM REQUIRES A RESTART FOR SELINUX **"
            echo "*******************************************"
        ;;
        enforcing)
            echo "*********************************"
            echo "** SYSTEM IS IN ENFORCING MODE **"
            echo "*********************************"
        ;;
    esac

    # Allow jenkins access to alternatives command to switch java version
    cat <<EOF >/etc/sudoers.d/89-jenkins-user-defaults
Defaults:jenkins !requiretty
jenkins ALL = NOPASSWD: /usr/sbin/alternatives
EOF

    echo "---> Updating operating system"
    yum clean all -q
    yum install -y -q deltarpm
    yum update -y -q

    # add in components we need or want on systems
    echo "---> Installing base packages"
    yum install -y -q @base https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
    # separate group installs from package installs since a non-existing
    # group with dnf based systems (F21+) will fail the install if such
    # a group does not exist
    yum install -y -q unzip xz puppet git git-review perl-XML-XPath xmlstarlet facter \
                      maven libltdl-dev python-tox crudini ansible

    # All of our systems require Java (because of Jenkins)
    # Install all versions of the OpenJDK devel but force 1.7.0 to be the
    # default

    echo "---> Configuring OpenJDK"
    yum install -y -q 'java-*-openjdk-devel'

    FACTER_OS=$(/usr/bin/facter operatingsystem)
    FACTER_OSVER=$(/usr/bin/facter operatingsystemrelease)
    case "$FACTER_OS" in
        Fedora)
            if [ "$FACTER_OSVER" -ge "21" ]
            then
                echo "---> not modifying java alternatives as OpenJDK 1.7.0 does not exist"
            else
                alternatives --set java /usr/lib/jvm/jre-1.7.0-openjdk.x86_64/bin/java
                alternatives --set java_sdk_openjdk /usr/lib/jvm/java-1.7.0-openjdk.x86_64
            fi
        ;;
        *)
            alternatives --set java /usr/lib/jvm/jre-1.7.0-openjdk.x86_64/bin/java
            alternatives --set java_sdk_openjdk /usr/lib/jvm/java-1.7.0-openjdk.x86_64
        ;;
    esac

    ########################
    # --- START LFTOOLS DEPS

    # Haskel Packages
    # Cabal update fails on a 1G system so workaround that with a swap file
    dd if=/dev/zero of=/tmp/swap bs=1M count=1024
    mkswap /tmp/swap
    swapon /tmp/swap

    # ShellCheck
    yum install -y cabal-install
    cabal update
    cabal install "Cabal<1.18"  # Pull Cabal version that is capable of building shellcheck
    cabal install --bindir=/usr/local/bin "shellcheck-0.4.6"  # Pin shellcheck version

    # Needed to parse OpenStack commands used by infra stack commands
    # to initialize Heat template based systems.
    yum install -y jq

    # --- END LFTOOLS DEPS
    ########################
}

ubuntu_systems() {
    # Ignore SELinux since slamming that onto Ubuntu leads to
    # frustration

    # Allow jenkins access to update-alternatives command to switch java version
    cat <<EOF >/etc/sudoers.d/89-jenkins-user-defaults
Defaults:jenkins !requiretty
jenkins ALL = NOPASSWD: /usr/bin/update-alternatives
EOF

    # Validate contents of fstab in base image
    # sed will return OK even if match was not found, so a simple grep will do
    [[ -d /w ]] || mkdir /w
    if ! grep -s "defaults,size=2g" /etc/fstab > /dev/null; then
        echo "ERROR: baseline.sh ($((LINENO-3))): Contents of /etc/fstab unexpected"
        exit 1
    fi
    sed -i s:size=2g:size=3g: /etc/fstab

    export DEBIAN_FRONTEND=noninteractive
    cat <<EOF >> /etc/apt/apt.conf
APT {
  Get {
    Assume-Yes "true";
    allow-change-held-packages "true";
    allow-downgrades "true";
    allow-remove-essential "true";
  };
};

Dpkg::Options {
  "--force-confdef";
  "--force-confold";
};

EOF

    echo "---> Updating operating system"
    apt-get update
    apt-get upgrade

    # add in stuff we know we need
    echo "---> Installing base packages"
    ensure_ubuntu_install unzip xz-utils puppet git git-review libxml-xpath-perl \
                          xmlstarlet facter maven libltdl-dev python-tox crudini

    # install newer Ansible
    echo "---> Installing ansible"
    apt-add-repository -y ppa:ansible/ansible
    apt-get update
    ensure_ubuntu_install ansible

    # install Java 7
    echo "---> Configuring OpenJDK"
    ensure_ubuntu_install openjdk-7-jdk

    # make jdk8 available
    add-apt-repository -y ppa:openjdk-r/ppa
    apt-get update
    # We need to force openjdk-8-jdk to install
    ensure_ubuntu_install openjdk-8-jdk

    # make sure that we still default to openjdk 7
    update-alternatives --set java /usr/lib/jvm/java-7-openjdk-amd64/jre/bin/java
    update-alternatives --set javac /usr/lib/jvm/java-7-openjdk-amd64/bin/javac

    ########################
    # --- START LFTOOLS DEPS

    # Haskel Packages
    # Cabal update fails on a 1G system so workaround that with a swap file
    dd if=/dev/zero of=/tmp/swap bs=1M count=1024
    mkswap /tmp/swap
    chmod 600 /tmp/swap
    swapon /tmp/swap

    # ShellCheck
    ensure_ubuntu_install cabal-install
    cabal update
    cabal install --bindir=/usr/local/bin "shellcheck-0.4.6"  # Pin shellcheck version

    # Needed to parse OpenStack commands used by infra stack commands
    # to initialize Heat template based systems.
    ensure_ubuntu_install jq

    # --- END LFTOOLS DEPS
    ########################

    # Add some hostname aliases for loop-back

    echo "---> Updating /etc/hosts"
cat <<EOF >> /etc/hosts

127.0.0.1 peer0.org1.example.com peer1.org1.example.com
127.0.0.1 peer0.org2.example.com peer1.org2.example.com
127.0.0.1 orderer.example.com
EOF

    apt-get install figlet sysvbanner html2text

    # Install sysstat and enable System Activity Monitoring
    apt-get install sysstat
    sed -i s:ENABLED=\"false\":ENABLED=\"true\": /etc/default/sysstat
    # Change collection interval to every 1 min (from 10)
    sed -i -e s:^5-55/10:*: -e 's:10 minutes:minute:' /etc/cron.d/sysstat
    # Disable the log rotation
    sed -i 's:^59:#59:'  /etc/cron.d/sysstat

    # disable unattended upgrades & daily updates
    echo '---> Disabling automatic daily upgrades'
    sed -ine 's/"1"/"0"/g' /etc/apt/apt.conf.d/10periodic
    echo 'APT::Periodic::Unattended-Upgrade "0";' >> /etc/apt/apt.conf.d/10periodic
}

all_systems() {
    # To handle the prompt style that is expected all over the environment
    # with how use use robotframework we need to make sure that it is
    # consistent for any of the users that are created during dynamic spin
    # ups
    echo 'PS1="[\u@\h \W]> "' >> /etc/skel/.bashrc

    # Do any Distro specific installations here
    echo "Checking distribution"
    FACTER_OS=$(/usr/bin/facter operatingsystem)
    case "$FACTER_OS" in
        RedHat|CentOS)
            if [ "$(/usr/bin/facter operatingsystemrelease | /bin/cut -d '.' -f1)" = "7" ]; then
                echo
                echo "---> CentOS 7"
                echo "No extra steps currently for CentOS 7"
                echo
            else
                echo "---> CentOS 6"
                echo "No extra steps currently for CentOS 6"
            fi
        ;;
        *)
            echo "---> $FACTER_OS found"
            echo "No extra steps for $FACTER_OS"
        ;;
    esac
}

echo "---> Attempting to detect OS"
# upstream cloud images use the distro name as the initial user
ORIGIN=$(if [ -e /etc/redhat-release ]
    then
        echo redhat
    else
        echo ubuntu
    fi)
#ORIGIN=$(logname)

case "${ORIGIN}" in
    fedora|centos|redhat)
        echo "---> RH type system detected"
        rh_systems
    ;;
    ubuntu)
        echo "---> Ubuntu system detected"
        ubuntu_systems
    ;;
    *)
        echo "---> Unknown operating system"
    ;;
esac

# execute steps for all systems
all_systems
