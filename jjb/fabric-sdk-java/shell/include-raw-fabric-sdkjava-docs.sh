#!/bin/bash -eu
#
# Copyright IBM Corp All Rights Reserved
#
# SPDX-License-Identifier: Apache-2.0
#
echo -e "\033[1;32m PUBLISH JAVA API DOCS" "\033[0m"

cd ${WORKSPACE}

# Short Head commit
sdk_java_commit=$(git rev-parse --short HEAD)
echo "-------> sdk_java_commit:" $sdk_java_commit
target_repo=$SDK_JAVA_GH_USERNAME.github.io.git
git config --global user.email "fabricsdkjavadocs@gmail.com"
git config --global user.name "sdkjavadocs"
# Clone SDK_Java API doc repository
git clone https://github.com/$SDK_JAVA_GH_USERNAME/$target_repo
# Copy API docs to target repository & push to gh-pages URL
cp -r target/site/apidocs/* $SDK_JAVA_GH_USERNAME.github.io
cd $SDK_JAVA_GH_USERNAME.github.io
git add .
git commit -m "SDK JAVA COMMIT - $sdk_java_commit"
# Credentials are stored as Global Variables in Jenkins
git config remote.gh-pages.url \
    https://$SDK_JAVA_GH_USERNAME:$SDK_JAVA_GH_PASSWORD@github.com/$SDK_JAVA_GH_USERNAME/$target_repo
# Push API docs to target repository
git push gh-pages master
