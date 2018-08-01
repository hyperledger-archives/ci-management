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

# vim: sw=4 ts=4 sts=4 et :

cat <<EOSSH >> /etc/ssh/ssh_config

# We don't want to SSH host key checking for dynamic hosts
Host 10.30.64.* 10.30.65.*
    StrictHostKeyChecking no
    UserKnownHostsFile /dev/null

EOSSH

# Make sure our gerrit server is known
cat <<EOKNOWN > /etc/ssh/ssh_known_hosts
[gerrit.hyperledger.org]:29418,[198.145.29.90]:29418 ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCdKbJmo/YIgjICSXfvbp/t4KazeT7qPIVRS4zwThD6erdVXwwVvq0Zxs3WTeaO/+d2qUFz+4afmlY9kHIAHb/ULwDXxHqJX86HfNFxuypnq7B6R0QidGPFq1ZpEVkYIqeUiJNoz1hD+TQYAUqNaFrGjnhuYHW0nCTzoNVs+7Exaz0+/sU8b0xfUs7Zn/80ds6sWpAY4bsar0pTA/3VBkuUM5i5UUOBB/dotpWOoEK2okoeKU4An4SYhLX0PdVajqc7lbvb0/Z7ePWnCzDYVUj2aGcv/HUtMOcgQp4USJ5lT0jBEYT4i3b+Lz5Q0Kog3Wh5F0fozHB/JuYsPYXVUccx
EOKNOWN
