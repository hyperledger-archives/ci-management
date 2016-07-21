#!/bin/bash
# x86_64 Specific Changes

# install npm and fabric node sdk dependencies
curl -sL https://deb.nodesource.com/setup_4.x | sudo bash -
apt-get install -y nodejs

npm install -g typescript
npm install -g typings
