#! /bin/bash

# The jenkins 'init' scripts should just ignore all errors

# The 'NVM' install is NOT a 'system' install of NVM, it is a 'user'
# install. After the install script runs, NVM is only available to the
# user who ran the nvm-install script

# The nvm-install script clones a repo into ~/.nvm and then adds a
# function definition for nvm to the users bashrc. To access the 'nvm'
# function from within a bash script, you must explicitly source the nvm setup
# script: source "$HOME/.nvm/nvm.sh"

ver=v0.31.0

wget -q -O /tmp/nvm-install.sh \
    https://raw.githubusercontent.com/creationix/nvm/$ver/install.sh

bash -e /tmp/nvm-install.sh
rm -rf /tmp/nvm-install.sh

# Delete the nvm entries from the .bashrc
sed -i '/NVM/d' $HOME/.bashrc

mkdir -p ~/bin
cat << 'EOF' > ~/bin/nvm
#! /bin/bash -e
source $HOME/.nvm/nvm.sh

# nvm is a shell 'function'
nvm "$@"

EOF
chmod 0755 ~/bin/nvm
