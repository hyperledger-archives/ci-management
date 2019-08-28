#! /bin/bash -u

# This script get called from the Jenkins Init Script that runs on the
# build agent before the build scripts are called. It runs as 'root'
# All errors are ignored (+e)

# Jenkins needs to own these directories sigh...
# softhsm may not be installed in all images
if [[ -d /etc/softhsm ]]; then
    chown -R jenkins:jenkins /var/lib/softhsm /etc/softhsm
fi

# Create HL Env file
# This file contains a library of bash functions & aliases
env_file=/home/jenkins/hl-env
cat <<EOF > $env_file
function echo_red()     { echo -ne "\\033[91m$*\\033[0m" ;}
function echo_green()   { echo -ne "\\033[32m$*\\033[0m" ;}
function echo_yellow()  { echo -ne "\\033[93m$*\\033[0m" ;}
function echo_blue()    { echo -ne "\\033[96m$*\\033[0m" ;}
function echo_reverse() { echo -ne "\\033[7m$*\\033[0m"  ;}
function echo_error()   { echo -ne "FATAL - $*"        ;}
EOF
chown jenkins:jenkins $env_file
