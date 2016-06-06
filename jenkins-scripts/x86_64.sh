#!/bin/bash

# Output the correct 'DOCKER_OPTS' to '/etc/default/docker'
service docker stop
echo "DOCKER_OPTS=\"-H tcp://0.0.0.0:2375 -H unix:///var/run/docker.sock\"" > /etc/default/docker
service docker start
