#! /usr/bin/bash

# Setup fluentd on ubuntu vm, add an rsyslog debug filedirectory, and send 
# syslog to a LogicMonitor account.
# How to run: Open the vm terminal and download the script to the root dir.
# Make it executable: `sudo chmod +x ubuntuVMfluentdSetupWithSyslogInput.sh`
# In LogicMonitor account: 
# - Enable Logs.
# - Under Settings > users & roles, create a user role. Take note of the 
#   access ID and access key. 
# In this script: 
# - replace <version_number> with version number for service. Do also remove 
#   the tags < > .
# - uncomment script # 4.0 to add rsyslog-fluentd pipeline debugging (optional)
# - in # 5.1 configure td-agent to send logs to LM:
#    - replace <company_name> with the name of your account (is your account 
#      name hello.logicmonitor.com, then your company_name is hello.)
#    - replace <access_id> with the access ID of the role you created.
#    - replace <access_key> with the roles' access key.

# 0.0 Run as root
sudo -s

# 1.0 Pre-installation

# 1.1 install dependencies
apt-get install gcc build-essential curl
apt-get autoremove

# 1.2.1 set up latest chrony
wget 'https://downloads.tuxfamily.org/chrony/chrony-<version.number>.tar.gz'
tar -xvf chrony-<version.number>.tar.gz
cd chrony-<version_number>
./configure
make
make install

# 1.2.2 chrony minimal config
cd /etc
touch chrony.conf
echo $'

pool pool.ntp.org iburst
makestep 1.0 3
rtcsync

' >> chrony.conf

# 1.2.3 start chrony daemon and check status
cd ~/chrony-<version.number>
./chronyd
chronyc tracking

# 1.2.4 add chrony daemon to autostart
systemctl enable chrony

# 1.3 Increase Max # of File Descriptors
cd ~/etc/security
echo $'

# fluentd limits\n\n\
root  soft  nofile  65536
root  hard  nofile  65536
*     soft  nofile  65536
*     hard  nofile  65536

' >> /etc/security/limits.conf
reboot

# 1.4 Recommended for distros with large datastreams, and multiple fluentd nodes:
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
# Expected output in terminal: {timestamp} debug.test: {"test":"it worked!"}
curl -X POST -d 'json={"test":"it worked!"}' http://localhost:8888/debug.test
tail -n 1 /var/log/td-agent/td-agent.log

# 3.0 setup syslog input

# 3.1 add UDP input to rsyslog
echo $'
# provides UDP syslog reception
module(load="imudp")
input(type="imudp" port="5140")
' >> /etc/rsyslog.conf

# 3.2 enable rsyslog. Wanted status == running
systemctl restart rsyslog.service
systemctl status rsyslog.service

# 3.3 td-agent minimal syslog input config
echo $'\n\n
<source>
  @type syslog
  port 5140
  bind 0.0.0.0
  tag system
</source>
' >> /etc/td-agent/td-agent.conf

#3.4 rsyslog send to port 5140
touch ~/etc/rsyslog.d/40-fluentd.conf
echo $'\n\n
# Send log messages to Fluentd
*.* @127.0.0.1:5140
' > /etc/rsyslog.d/40-fluentd.conf
reboot

#4.0 # (optional) output syslog to local file
#    # Uncomment the following 15 rows to add rsyslog-fluentd debug file storage.
# mkdir /var/log/td-agent/debug.log
# chmod +777 /var/log/td-agent/debug.log
# echo $'
# <match pattern>
#   @type file
#   path /var/log/td-agent/debug.log
#   compress gzip
#   <buffer>
#     timekey 1m
#     timekey_use_utc true
#     timekey_wait 1m
#   </buffer>
# </match>
# ' >> /etc/td-agent/td-agent.conf
# systemctl restart td-agent

# 5.0 Add LM_out fluentd plugin
td-agent-gem install lm-logs-fluentd

# 5.1 configure td-agent to send logs to LM
echo $'
# Match events tagged with "lm.**" and
# send them to LogicMonitor
<match system.**>
    @type lm
    company_name <company_name>
    resource_mapping {"event_key": "lm_property"}
    access_id <access_id>
    access_key <access_key>
    tag system
    flush_interval 1s
    debug true
</match>
' >> /etc/td-agent/td-agent.conf
systemctl restart td-agent

# Done!
# If you have setup syslog debug files, you can check that logs 
# are coming in to /var/log/td-agent/debug.log. In the first day, 
# you will se log buffers. The buffers will be archived once per 24 hours.
# In a couple of minutes' time, you should be able to see syslog from your 
# ubuntu vm in the LogicMonitor account.

# Diagnostics: 

# a. Check status of services:
# systemctl status rsyslog td-agent chrony

# a. see logs from fluentd:
# tail -f /var/log/td-agent/td-agent.log

# b. see incoming syslog:
# tail -f /var/log/syslog

# c. check system logs for rsyslog errors:
# sudo cat /var/log/messages | grep rsyslog
