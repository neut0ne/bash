#! /bin/bash

echo $'\n Purging lm-logs-fluentd plugin, td-agent and chrony...\n'
apt-get purge td-agent chrony
apt-get autoremove
echo $'Cleaning up modified configuration files...'
sed -i '/# provides UDP syslog reception for lm logs fluentd/,+2d' /etc/rsyslog.conf
sed -i '/# lm logs fluentd limits/,+4d' /etc/security/limits.conf
sed -i '/pool pool.ntp.org iburst/,+2d' /etc/chrony.conf
rm /etc/rsyslog.d/40-fluentd.conf
echo $'Clearing system cache...\n'
sync; echo 3 > /proc/sys/vm/drop_caches

echo $'LM logs fluentd setup is uninstalled.\n'
