#!/bin/bash
# x86_64 Specific Changes

# install npm and fabric node sdk dependencies
curl -sL https://deb.nodesource.com/setup_4.x | sudo bash -
apt-get install -y nodejs
apt-get install -y maven

npm install -g typescript
npm install -g typings
npm install -g typedoc
