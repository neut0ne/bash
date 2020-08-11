#! /usr/bin/bash

# Setup fluentd on ubuntu vm, and add syslog input
# How to run: Open the vm terminal and download the script to the root dir.
# Make it executable: 
# If you don't have bash installed: sudo apt-get install bash
# DON'T FORGET! Replace all curly brackets with current version number!

# run as root
sudo -s

# 1.0 Pre-installation

# 1.1 install dependencies
apt-get install gcc build-essential curl
apt-get autoremove

# 1.2.1 set up latest chrony
wget 'https://downloads.tuxfamily.org/chrony/chrony-{version.number}.tar.gz'
tar -xvf chrony-{version.number}.tar.gz
cd chrony-{version.number}
./configure
make
make install

# 1.2.2 chrony minimal config
cd /etc
touch chrony.conf
echo $'pool pool.ntp.org iburst\nmakestep 1.0 3\nrtcsync' >> chrony.conf

# 1.2.3 start chrony daemon
cd ~/chrony-{version.number}
./chronyd

# 1.2.4 add chrony daemon to autostart

# 1.3 Increase Max # of File Descriptors
cd ~/etc/security
echo $'\n# fluentd limits\n\nroot soft nofile 65536\nroot hard nofile 65536\n* soft nofile 65536\n* hard nofile 65536' >> /etc/security/limits.conf
reboot

# 1.4 Recommended for distros with large datastreams, multiple fluentd nodes etc:
# Optimize Network Kernel Parameters; see fluentd official pre-installation docs
# https://docs.fluentd.org/installation/before-install

# 2.0 Install Fluentd

# 2.1 Install Fluentd deb package with td-agent 4 for Ubuntu 20.04 Focal.
# for other versions, see https://docs.fluentd.org/installation/install-by-deb
curl -L https://toolbelt.treasuredata.com/sh/install-ubuntu-focal-td-agent4.sh | sh

# 2.2 start td-agent daemon and check that status == running
systemctl start td-agent.service
systemctl status td-agent.service

# 2.3 send a sample log over http.
# Expected output in terminal: {date} {time} -0700 debug.test: {"test":"it worked!"}
curl -X POST -d 'json={"test":"it worked!"}' http://localhost:8888/debug.test
tail -n 1 /var/log/td-agent/td-agent.log

