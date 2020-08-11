#! /usr/bin/bash

# Setup fluentd on ubuntu vm, and add syslog input
# How to run: Open the vm terminal and download the script to the root dir.
# Make it executable: 
# If you don't have bash installed: sudo apt-get install bash
# DON'T FORGET! Replace all curly brackets with current version number!

# run as root
sudo -s

# install dependencies
apt-get install gcc build-essential curl
apt-get autoremove

# set up latest chrony
wget 'https://downloads.tuxfamily.org/chrony/chrony-{version.number}.tar.gz'
tar -xvf chrony-{version.number}.tar.gz
cd chrony-{version.number}
./configure
make
make install

# chrony minimal config
cd /etc
touch chrony.conf
echo $'pool pool.ntp.org iburst\nmakestep 1.0 3\nrtcsync' >> chrony.conf

# start chrony daemon
cd ~/chrony-{version.number}
./chronyd

# Increase Max # of File Descriptors
cd ~/etc/security
echo $'\n# fluentd limits\n\nroot soft nofile 65536\nroot hard nofile 65536\n* soft nofile 65536\n* hard nofile 65536' >> /etc/security/limits.conf
reboot

# Recommended for distros with large datastreams, multiple fluentd nodes etc:
# Optimize Network Kernel Parameters; see fluentd official pre-installation docs
# https://docs.fluentd.org/installation/before-install




