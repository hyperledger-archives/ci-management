#!/bin/bash

# vim: sw=2 ts=2 sts=2 et :

rm -rf /etc/Pegasus/*.cnf /etc/Pegasus/*.crt /etc/Pegasus/*.csr \
  /etc/Pegasus/*.pem /etc/Pegasus/*.srl /root/anaconda-ks.cfg \
  /root/anaconda-post.log /root/initial-setup-ks.cfg /root/install.log \
  /root/install.log.syslog /var/cache/fontconfig/* /var/cache/gdm/* \
  /var/cache/man/* /var/lib/AccountService/users/* /var/lib/fprint/* \
  /var/lib/logrotate.status /var/log/*.log* /var/log/BackupPC/LOG \
  /var/log/ConsoleKit/* /var/log/anaconda.syslog /var/log/anaconda/* \
  /var/log/apache2/*_log /var/log/apache2/*_log-* /var/log/apt/* \
  /var/log/aptitude* /var/log/audit/* /var/log/btmp* /var/log/ceph/*.log \
  /var/log/chrony/*.log /var/log/cron* /var/log/cups/*_log /var/log/debug* \
  /var/log/dmesg* /var/log/exim4/* /var/log/faillog* /var/log/gdm/* \
  /var/log/glusterfs/*glusterd.vol.log /var/log/glusterfs/glusterfs.log \
  /var/log/httpd/*log /var/log/installer/* /var/log/jetty/jetty-console.log \
  /var/log/journal/* /var/log/lastlog* /var/log/libvirt/libvirtd.log \
  /var/log/libvirt/lxc/*.log /var/log/libvirt/qemu/*.log \
  /var/log/libvirt/uml/*.log /var/log/lightdm/* /var/log/mail/* \
  /var/log/maillog* /var/log/messages* /var/log/ntp /var/log/ntpstats/* \
  /var/log/ppp/connect-errors /var/log/rhsm/* /var/log/sa/* /var/log/secure* \
  /var/log/setroubleshoot/*.log /var/log/spooler* /var/log/squid/*.log \
  /var/log/syslog* /var/log/tallylog* /var/log/tuned/tuned.log /var/log/wtmp* \
  /var/named/data/named.run

rm -rf ~/.viminfo /etc/ssh/ssh*key* /root/.ssh/*

# kill any cloud-init related bits
rm -rf /var/lib/cloud/*

# clean-up any manual packer uploads
rm -rf /tmp/packer

# Force a system sync and sleep to get around any SSD issues
echo "Forcing sync and sleep for 10sec"
sync
sleep 10
