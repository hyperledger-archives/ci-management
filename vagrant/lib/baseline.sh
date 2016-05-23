#!/bin/bash

# vim: ts=4 sw=4 sts=4 et tw=72 :

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

    echo "---> Updating operating system"
    yum clean all -q
    # speed up the system update
    yum install -y -q deltarpm
    yum update -y -q

    # add in components we need or want on systems
    echo "---> Installing base packages"
    # Add EPEL on CentOS systems
    case "${ORIGIN}" in
            centos)
                echo "---> Installing EPEL"
                yum install -y -q @base https://dl.fedoraproject.org/pub/epel/epel-release-latest-7.noarch.rpm
            ;;
            *)
                echo "---> EPEL not needed"
            ;;
    esac
    # separate group installs from package installs since a non-existing
    # group with dnf based systems (F21+) will fail the install if such
    # a group does not exist
    yum install -y -q unzip xz puppet git perl-XML-XPath

    # All of our systems require Java (because of Jenkins)
    # Install all versions of the OpenJDK devel but force 1.7.0 to be the
    # default

    echo "---> Configuring OpenJDK"
    yum install -y -q 'java-*-openjdk-devel'
}

ubuntu_systems() {
    # Ignore SELinux since slamming that onto Ubuntu leads to
    # frustration

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
    apt-get install unzip xz-utils puppet git libxml-xpath-perl

    # install Java 7
    echo "---> Configuring OpenJDK"
    apt-get install openjdk-7-jdk

    # make jdk8 available
    add-apt-repository -y ppa:openjdk-r/ppa
    apt-get update
    # We need to force openjdk-8-jdk to install
    apt-get install openjdk-8-jdk

    # make sure that we still default to openjdk 7
    update-alternatives --set java /usr/lib/jvm/java-7-openjdk-amd64/jre/bin/java
    update-alternatives --set javac /usr/lib/jvm/java-7-openjdk-amd64/bin/javac

    echo "---> Forcing CA certificate update"
    update-ca-certificates -f
}

all_systems() {
    # Do any Distro specific installations here
    echo "Checking distribution"
    FACTER_OS=$(/usr/bin/facter operatingsystem)
    echo "---> ${FACTER_OS} found"
    echo "No extra steps for ${FACTER_OS}"
}

echo "---> Attempting to detect OS"
# upstream cloud images use the distro name as the initial user
ORIGIN=$(logname)

case "${ORIGIN}" in
    fedora|centos)
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
