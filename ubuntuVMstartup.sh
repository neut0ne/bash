#! /usr/bin/bash

# Startup script to run on a newly spinned-up Ubuntu vm
# Prep on host: Download current version of virtualbox Guest Additions.
# add Guest Addition to IDE secondary master.
# in settings > general > advanced: set 
# shared clipboard = bidirectional
# Drag n' Drop = bidirectional
#
# Script: Replace curly brackets with dirnames in the vm.

sudo -s
apt-get update
apt-get upgrade
apt-get autoremove
apt-get install make gcc openssh-server linux-headers-$(uname -r)
./media/{user}/{opticaldrive}/autorun.sh

