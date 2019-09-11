#!/bin/bash
#
# SPDX-License-Identifier: Apache-2.0
##############################################################################
# Copyright (c) 2018 IBM Corporation, The Linux Foundation and others.
#
# All rights reserved. This program and the accompanying materials
# are made available under the terms of the Apache License 2.0
# which accompanies this distribution, and is available at
# https://www.apache.org/licenses/LICENSE-2.0
##############################################################################

# This script makes several basic commit message validations.
# This is with the purpose of keeping up with the aesthetics
# of our code.

# Verify if the commit message contains JIRA URLs.
# its-jira pluggin attempts to process jira links and breaks.

JIRA_LINK=`git rev-list --format=%B --max-count=1 HEAD | grep -io 'http[s]*://jira\..*'`
if [[ ! -z "$JIRA_LINK" ]]
then
  echo 'Error: Remove JIRA URLs from commit message'
  echo 'Add jira references as: Issue: <JIRAKEY>-<ISSUE#>, instead of URLs'
  exit 1
fi
