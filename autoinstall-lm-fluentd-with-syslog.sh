#! /bin/bash

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
# - optional: uncomment script # 4.0 to add rsyslog-fluentd pipeline debugging

# 0.0 enter credentials
read -p $'Enter company_name (the LogicMonitor account name):\n' company_name
read -p $'Enter resource_mapping key:\n' resource_mapping_key
read -p $'Enter resource_mapping key value:\n' resource_mapping_key_value
read -p $'Enter role access_ID:\n' access_ID
read -p $'Enter role access_key:\n' access_key

# 1.0 install dependencies
echo $'\n Installing dependencies...\n'
apt-get install -y grep gcc build-essential curl
apt-get autoremove
echo $'...done installing dependencies\n'

# 1.2 install chrony, Fluentd deb package, and lm_out fluentd plugin
echo $'Installing chrony...\n'
apt-get install chrony
systemctl enable chrony
echo $'\nInstalling Fluentd deb package td-agent 4 for Ubuntu 20.04 focal...\n'


echo "Configuring UDP for rsyslog..."
printf -v s "%s\n" '
# provides UDP syslog reception for lm logs fluentd
module(load="imudp")
input(type="imudp" port="5140")
'
grep -Fxq "$s" /etc/rsyslog.conf
if grep -Fxq "$s" /etc/rsyslog.conf;
then
    echo "Config already exists. Continuing..."
else
    echo "$s" >> /etc/rsyslog.conf
fi

# 3.0 apply configurations
echo "Applying configurations..."
systemctl restart chrony td-agent rsyslog
if [ $? -eq 0 ]; then
    echo $'\n\n Fluentd and lm-logs syslog setup completed.\n'
    echo $'Find the installation log in /tmp.\n'
else
    echo $'Configuration failed with an error.\n'
fi
#! /bin/bash

#exec 3>&1 4>&2
#trap 'exec 2>&4 1>&3' 0 1 2 3
#exec 1>~/tmp/LM_fluentd_install$(date).log 2>&1

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
# - optional: uncomment script # 4.0 to add rsyslog-fluentd pipeline debugging

# 0.0 Installation log:
# today=$(date +"%Y-%m-%d")
# automated_LM_fluentd_setup.sh 2>&1 | tee -a /tmp/LM_fluentd_install${today}.log

# 0.0 enter credentials
read -p $'Enter company_name (the LogicMonitor account name):\n' company_name
read -p $'Enter resource_mapping key:\n' resource_mapping_key
read -p $'Enter resource_mapping key value:\n' resource_mapping_key_value
read -p $'Enter role access_ID:\n' access_ID
read -p $'Enter role access_key:\n' access_key

# 1.0 install dependencies
echo $'\n Installing dependencies...\n'
apt-get install -y grep gcc build-essential curl
apt-get autoremove
echo $'...done installing dependencies\n'

# 1.2 install chrony, Fluentd deb package, and lm_out fluentd plugin
echo $'Installing chrony...\n'
apt-get install chrony
systemctl enable chrony
echo $'\nInstalling Fluentd deb package td-agent 4 for Ubuntu 20.04 focal...\n'
curl -L 'https://toolbelt.treasuredata.com/sh/install-ubuntu-focal-td-agent4.sh' | sh
echo $'Fluentd core has finished installing. On to the LM plugin...'
echo $'installing lm-logs-fluentd plugin...\n'
td-agent-gem install lm-logs-fluentd
echo $'...done installing services\n'

# 1.3 Recommended for distros with large datastreams, and multiple fluentd nodes:
# Optimize Network Kernel Parameters; see fluentd official pre-installation docs
# https://docs.fluentd.org/installation/before-install

# 2.0 configuration

# 2.1 chrony:
echo $'\nConfiguring chrony...'
printf -v s "%s\n" '
pool pool.ntp.org iburst
makestep 1.0 3
rtcsync
'
grep -Fxq "$s" /etc/chrony.conf
if grep -Fxq "$s" /etc/chrony.conf;
then
    echo "Config already exists. Continuing..."
else
    echo "$s" >> /etc/chrony.conf
fi

# 2.2 Increase Max # of File Descriptors
echo "Configuring File Descriptor Limits for Fluentd..."
printf -v s "%s\n" '

# lm logs fluentd limits
root  soft  nofile  65536
root  hard  nofile  65536
*     soft  nofile  65536
*     hard  nofile  65536
'
grep -Fxq "$s" /etc/security/limits.conf
if grep -Fxq "$s" /etc/security/limits.conf;
then
    echo "Config already exists. Continuing..."
else
    echo "$s" >> /etc/security/limits.conf
fi

# 2.3 td-agent (fluentd):
echo "Configuring td-agent (Fluentd main, and lm-logs-fluentd plugin)..."
echo $"
# syslog input
<source>
  @type syslog
  port 5140
  bind 0.0.0.0
  tag lm.system
  message_format auto
</source>

# add resource mapping to syslogs
<filter lm.**>
  @type record_transformer
  <record>
    _lm.resourceId {\"$resource_mapping_key\":\"$resource_mapping_key_value\"}
#    tag ${tag}
  </record>
  tag lm.system
</filter>

# Match events tagged with "lm.system**" and
# send them to LogicMonitor
<match lm.system.**>
    @type lm
    company_name $company_name
    resource_mapping {\"$resource_mapping_key\":\"$resource_mapping_key_value\"}
    access_id $access_ID
    access_key $access_key
    flush_interval 1s
    debug true
</match>
" >> /etc/td-agent/td-agent.conf

# 2.4 # (optional) syslog debug output to local file
#     # Uncomment the following 15 rows to add local rsyslog-fluentd debug log.
#echo $"creating rsyslog debug repository, and configuring syslog debugging\n"
#mkdir /var/log/td-agent/debug.log
#chmod +777 /var/log/td-agent/debug.log
#echo $'\n
#<match pattern>
#  @type file
#  path /var/log/td-agent/debug.log
#  compress gzip
#  <buffer>printf -v s "%s\n" '
#    timekey 1m
#    timekey_use_utc true
#    timekey_wait 1m
#  </buffer>
#</match>
#' >> /etc/td-agent/td-agent.conf

# 2.5 rsyslog send to port 5140
echo "Configuring rsyslog output destination..."
printf -v s "%s\n" '
# Send log messages to Fluentd
*.* @127.0.0.1:5140
'
grep -Fxq "$s" /etc/rsyslog.d/40-fluentd.conf
if grep -Fxq "$s" /etc/rsyslog.d/40-fluentd.conf;
then
    echo "Config already exists. Continuing..."
else
    echo "adding config /etc/rsyslog.d/40-fluentd.conf"
    echo "$s" >> /etc/rsyslog.d/40-fluentd.conf
fi

# 2.6 add UDP input to rsyslog
echo "Configuring UDP for rsyslog..."
printf -v s "%s\n" '
# provides UDP syslog reception for lm logs fluentd
module(load="imudp")
input(type="imudp" port="5140")
'
grep -Fxq "$s" /etc/rsyslog.conf
if grep -Fxq "$s" /etc/rsyslog.conf;
then
    echo "Config already exists. Continuing..."
else
    echo "$s" >> /etc/rsyslog.conf
fi

# 3.0 apply configurations
echo "Applying configurations..."
systemctl restart chrony td-agent rsyslog
if [ $? -eq 0 ]; then
    echo $'\n\n Fluentd and lm-logs syslog setup completed.\n'
    echo $'Find the installation log in /tmp.\n'
else
    echo $'Configuration failed with an error.\n'
fi
echo $'Current fluentd status:\n\n'
tail -f -n 50 /var/log/td-agent/td-agent.log

# Done!
# If you have setup syslog debug files, you can check that logs
# are coming in to /var/log/td-agent/debug.log. In the first day,
# you will se log buffers. The buffers will be archived once per 24 hours.
# If configurations are accurate, you will be able to see syslog from your
# ubuntu vm in the LogicMonitor account right away.

# Diagnostics:

# a. Check status of services:
# systemctl status rsyslog td-agent chrony
# chronyc tracking

# b. see logs from fluentd:
# tail -f /var/log/td-agent/td-agent.log

# c. see incoming syslog:
# tail -f /var/log/syslog

# d. check system logs for rsyslog errors:
# sudo cat /var/log/messages | grep rsyslog

# e. send a sample log over http.
# Expected output in terminal: {timestamp} debug.test: {"test":"it worked!"}
# curl -X POST -d 'json={"test":"it worked!"}' http://localhost:8888/debug.test
# tail -n 1 /var/log/td-agent/td-agent.log
