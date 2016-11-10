#!/bin/bash
# vi: ts=4 sw=4 sts=4 et :

/bin/sed -i 's/ requiretty/ !requiretty/' /etc/sudoers;
