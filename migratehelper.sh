#!/bin/bash

echo "#*************************************************************************# "
echo "# Note we are NOT including >>"
echo "# /home/e-smith/{files,shares} "
echo "# /home/e-smith/db/mysql*/{daily,hourly}"
echo "# "
echo "# You are responsible for backing up and restoring them separately"
echo "#*************************************************************************# "

TEST="n"  # Set Test mode default
VERSION=1 # Just because
NOCHECK="0"

# ===========================================================================

function usage() { # Function: Print a help message.
  echo "Usage: $0 [ -t Enable Test mode ] [ -n no-check ] [ -v Version ] [ -h Help ]" 1>&2
}

function exit_abnormal() { # Function: Exit with error.
  usage
  exit 1
}

function prompt_confirm() {
  while true; do
    read -r -n 1 -p "${1:-Continue?} [y/n]: " REPLY
    case $REPLY in
    [yY])
      echo
      return 0
      ;;
    [nN])
      echo
      return 1
      ;;
    *) printf " \033[31m %s \n\033[0m" "invalid input" ;;
    esac
  done
}

while getopts ":vthn" options; do # Loop: Get the next option;
  # use silent error checking;
  # options have no arguments
  case "${options}" in #
  v)                   # If the option is n,
    echo "Version $VERSION"
    exit_abnormal
    ;;
  t)         # If the option is t,
    TEST="y" # Set $TEST
    ;;
  n)
    echo "Checking"
    NOCHECK="1"
    ;;
  h)
    exit_abnormal
    ;;

  \?) # If unknown (any other) option:
    echo "invalid_option"
    exit_abnormal # Exit abnormally.
    ;;

  *) # If unknown (any other) option:
    echo "unknown_option"
    exit_abnormal # Exit abnormally.
    ;;

    # Me hacking about
    #    :)                                    # If expected argument omitted:
    #      echo "Error: -${OPTARG} requires an argument."
    #      exit_abnormal                       # Exit abnormally.
    #      ;;

  esac

done

if [ "$NOCHECK" = "0" ]; then
  prompt_confirm "Can we start?" || exit 0
fi

# Let's go.
echo "Starting - please be patient"

if [ "$TEST" = "y" ]; then
  echo "We are in TEST mode. No backup will be created or services affected"
else
  echo "We are in REAL mode."
  echo "This creates a backup file for restore"
  echo "The file includes and excludes various items"
  echo "All files, mails and MySQL DBS are not included, except dumps in /home/e-smith/db/mysql*/"
  echo "if you took the time to execute signal-event pre-backup, before"
  echo "We will create the backup file like this"
  echo "tar cvzf /mnt/backup/smeserver.tgz -T dir.list --exclude-from exclude.list"
  echo ""
  echo "After the script has finished all mail/file/web services will remain stopped"
  echo "This is to ensure your backup is up to date untill you transfer it to new server."
  echo "Copy the backup to your new server, and manually copy over the remaining files"
fi

# Added failure check
# https://github.com/koalaman/shellcheck/wiki/SC2164

cd /root || exit_abnormal

cat <<'EOF' >dir.list
/etc/e-smith/templates-custom
/etc/e-smith/templates-user-custom
/etc/group
/etc/gshadow
/etc/passwd
/etc/samba/secrets.tdb
/etc/samba/smbpasswd
/etc/shadow
/etc/ssh
/etc/sudoers
/root
/home/e-smith/Maildir
/home/e-smith/ssl.crt
/home/e-smith/ssl.key
/home/e-smith/dkim_keys
/home/e-smith/db
/var/lib/dhcpd/dhcpd.leases
/var/log/qpsmtpd
/var/log/sqpsmtpd
/var/log/qmail
/var/log/httpd/
/var/log/dovecot/
/var/log/squid/
/var/log/iptables/
/var/spool/mail/
/var/spool/spamd/
/var/spool/cron/
EOF

[ -e /etc/smbpasswd ] && cat <<'EOF' >>dir.list
/etc/smbpasswd
EOF

[ -e /var/log/samba/samba_audit ] && cat <<'EOF' >>dir.list
/var/log/samba/samba_audit
EOF

[ -e /etc/samba/schannel_store.tdb ] && cat <<'EOF' >>dir.list
/etc/samba/schannel_store.tdb
EOF

[ -e /var/lib/samba/group_mapping.tdb ] && cat <<'EOF' >>dir.list
/var/lib/samba/group_mapping.tdb
EOF

[ -e /var/lib/samba/account_policy.tdb ] && cat <<'EOF' >>dir.list
/var/lib/samba/account_policy.tdb
EOF

[ -e /var/log/samba/samba_audit ] && cat <<'EOF' >>dir.list
/var/log/samba/samba_audit
EOF

[ -e /var/service/qpsmtpd/config/dkimkeys/ ] && cat <<'EOF' >>dir.list
/var/service/qpsmtpd/config/dkimkeys/
EOF

## add here inclusion from db key

## exclude files
cat <<EOF >exclude.list
/home/e-smith/db/mysql/daily
/home/e-smith/db/mysql/hourly
/home/e-smith/db/mysql55/daily
/home/e-smith/db/mysql55/hourly
/home/e-smith/db/mysql57/daily
/home/e-smith/db/mysql57/hourly
/home/e-smith/files
/home/e-smith/shares
/etc/e-smith/templates-custom/etc/httpd/conf/httpd.conf/20LoadModule80PHP
/etc/e-smith/templates-custom/etc/hosts.allow/sshd
/etc/e-smith/templates-custom/etc/httpd/conf/httpd.conf/35SSL00Listen443
/etc/e-smith/templates-custom/etc/dhcpd.conf/25DomainNameServers
/etc/e-smith/templates-custom/etc/dhcpd.conf/25LeaseTimeDefault
/etc/e-smith/templates-custom/etc/dhcpd.conf/25LeaseTimeMax
/etc/e-smith/templates-custom/etc/dhcpd.conf/25Routers
EOF

## add here exclusion from db key
# Added -print0 here - also needs -0 on xargs
# https://github.com/koalaman/shellcheck/wiki/SC2038
# search for local script added
find /usr/local/bin/ -type f -print0 | xargs -0 -I % sh -c "rpm -qf % 2>&1 > /dev/null || echo % >> dir.list"
# search for local dir script added
find /usr/local/ -maxdepth 1 -type d -print0 | xargs -0 -I % sh -c "rpm -qf % 2>&1 > /dev/null || echo % >> dir.list"
# search for cron files not owned by a rpm
find /etc/cron.* -type f -print0 | xargs -0 -I % sh -c "rpm -qf % 2>&1 > /dev/null || echo % >> dir.list"
# search for udev rules not owned by a rpm ! could add an option there in case you change of hardware
# migration from sme9 to sme10 will change the names of net if, and this will make it worst
find /etc/udev/rules.d/ -type f -print0 | xargs -0 -I % sh -c "rpm -qf % 2>&1 > /dev/null || echo % >> dir.list"
# search for spamassassin user created config
find /etc/mail/spamassassin -maxdepth 1 -type f -print0 | xargs -0 -I % sh -c "rpm -qf % 2>&1 > /dev/null || echo % >> dir.list"

##################
#
# here starts the magic
# we backup each known contribs folder
#
##################
#smeserver-awstats.noarch
# data will be in /home/e-smith/files/users/admin
# we only backup the config files
rpm -q smeserver-awstats >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/etc/e-smith/web/panels/manager/cgi-bin/.awstats/
EOF
# see with Daniel if they have a specific config
#rpm -q awstats >/dev/null 2>&1 && cat <<'EOF' >> dir.list
#/var/lib/awstats
#EOF
#for those we assume you handle yourself the backup or the pools in /var/lib/BackupPC
rpm -q smeserver-BackupPC >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/etc/BackupPC
EOF
rpm -q smeserver-BackupPC4 >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/etc/BackupPC
EOF
rpm -q smeserver-bandwidthd >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/www/bandwidthd/
EOF
#smeserver-clamav-unofficial-sigs and clamav-unofficial-sigs
rpm -q smeserver-clamav-unofficial-sigs >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/clamav-unofficial-sigs/
EOF
#smeserver-dansguardian smeserver-dansguardian-panel
rpm -q smeserver-dansguardian >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/etc/dansguardian/
EOF
#smeserver-denyhosts
rpm -q smeserver-denyhosts >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/denyhosts/
/etc/hosts.deny_ssh
/etc/hosts.deny_ssh.purge.bak
EOF
rpm -q smeserver-dl >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/dl/
EOF
rpm -q dokuwiki >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/etc/dokuwiki/acl.auth.php
/etc/dokuwiki/acronyms.conf
/etc/dokuwiki/entities.conf
/etc/dokuwiki/interwiki.conf
/etc/dokuwiki/local.php
/etc/dokuwiki/plugins.local.php
/etc/dokuwiki/scheme.conf
/var/lib/dokuwiki/data/attic
/var/lib/dokuwiki/data/index
/var/lib/dokuwiki/data/media
/var/lib/dokuwiki/data/media_attic
/var/lib/dokuwiki/data/media_meta
/var/lib/dokuwiki/data/meta
/var/lib/dokuwiki/data/pages
EOF
rpm -q dokuwiki >/dev/null 2>&1 && for D in /usr/share/dokuwiki/lib/plugins/*; do
  rpm -qf "$D" >/dev/null 2>&1 || echo "$D" >>dir.list
done

#rpm -q smeserver-dovecot >/dev/null  2>&1 && cat <<'EOF' >> dir.list
[ -e /etc/dovecot/sharemailbox ] && cat <<'EOF' >>dir.list
/etc/dovecot/sharemailbox/
EOF

#smeserver-durep
rpm -q smeserver-durep >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/durep
EOF
#smeserver-ezmlm-web
rpm -q smeserver-ezmlm-web >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/home/e-smith/files/ezmlm
EOF
[ -e /var/lib/phone ] && cat <<'EOF' >>dir.list
/var/lib/phone
EOF
rpm -q smeserver-freepbx >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/opt/freepbx
/var/lib/asterisk/
/etc/asterisk
/var/spool/asterisk/
/var/log/asterisk
/usr/local/sbin/amportal
/usr/local/sbin/fwconsole
/usr/sbin/amportal
/usr/sbin/fwconsole
EOF
# smeserver-fail2ban 
if [ -d /etc/fail2ban/action.d ]; then
  for F in $(ls /etc/fail2ban/action.d/);do
    rpm -qf /etc/fail2ban/action.d/$F >/dev/null 2>&1 || echo /etc/fail2ban/action.d/$F >> dir.list
  done
fi
if [ -d /etc/fail2ban/fail2ban.d ]; then
  for F in $(ls /etc/fail2ban/fail2ban.d/);do
    rpm -qf /etc/fail2ban/fail2ban.d/$F >/dev/null 2>&1 || echo /etc/fail2ban/fail2ban.d/$F >> dir.list
  done
fi
if [ -d /etc/fail2ban/filter.d ]; then
  for F in $(ls /etc/fail2ban/filter.d/);do
    rpm -qf /etc/fail2ban/filter.d/$F >/dev/null 2>&1 || echo /etc/fail2ban/filter.d/$F >> dir.list
  done
fi
if [ -d /etc/fail2ban/jail.d ]; then
  for F in $(ls /etc/fail2ban/jail.d/);do
    rpm -qf /etc/fail2ban/jail.d/$F >/dev/null 2>&1 || echo /etc/fail2ban/jail.d/$F >> dir.list
  done
fi
rpm -q smeserver-grr >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/usr/share/grr/images/
EOF
rpm -q ipasserelle-im >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/ejabberd/
/var/log/ejabberd.run
EOF
#smeserver-isoqlog
rpm -q smeserver-isoqlog >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/qmailtools/isoqlog/htdocs/
EOF
rpm -q smeserver-jappix >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/jappix/
/var/log/jappix
EOF
rpm -q smeserver-lemonldap-ng >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/lemonldap-ng/conf
/var/lib/lemonldap-ng/notifications
EOF
#smeserver-letsencrypt
#rpm -q smeserver-letsencrypt  >/dev/null  2>&1 && cat <<'EOF' >> dir.list
[ -d /etc/letsencrypt.sh/ ] && cat <<'EOF' >>dir.list
/etc/letsencrypt.sh/
EOF
[ -d /etc/dehydrated/ ] && cat <<'EOF' >>dir.list
/etc/dehydrated/
EOF

rpm -q smeserver-limesurvey >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/limesurvey/uploads
EOF
rpm -q ipasserelle-listes >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/mailman/
/usr/lib/mailman/aliases/
EOF
if [ -d /usr/share/mozilla-mcd/ ]; then
  for F in /usr/share/mozilla-mcd/*; do
    rpm -qf "$F" >/dev/null 2>&1 || echo "$F" >>dir.list
  done
fi
rpm -q smeserver-madsonic >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/madsonic/db/
/var/madsonic/madsonic.properties
/var/madsonic/madsonic.log
/var/madsonic/madsonic_sh.log
EOF
rpm -q smeserver-mailman >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/mailman/
/usr/lib/mailman/aliases/
EOF
rpm -q smeserver-nextcloud >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/usr/share/nextcloud/
EOF
rpm -q smeserver-ntop >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/ntop/
EOF
rpm -q phpki >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/opt/phpki/phpki-store/
/opt/phpki/html/config.php
EOF
rpm -q smeserver-openvpn-bridge >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/etc/openvpn/bridge/priv
/etc/openvpn/bridge/pub
/var/log/openvpn-bridge
EOF
rpm -q smeserver-openvpn-s2s >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/etc/openvpn/s2s/priv
/etc/openvpn/s2s/pub
/var/log/openvpn-s2s
EOF
rpm -q smeserver-openvpn-routed >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/etc/openvpn/routed/priv
/etc/openvpn/routed/pub
/var/log/openvpn-routed
EOF
rpm -q smeserver-phpki >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/opt/phpki/
EOF
rpm -q smeserver-phpki-ng >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/opt/phpki/
EOF
rpm -q pydio >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/pydio/files
/var/lib/pydio/personal
/var/lib/pydio/public
/var/log/pydio
EOF

rpm -q smeserver-sarg >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/www/sarg/
EOF
#smeserver-sme8admin
rpm -q smeserver-sme8admin >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/sme8admin/
EOF
#smeserver-sme9admin
rpm -q smeserver-sme9admin >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/sme9admin/
EOF
rpm -q smeserver-smeadmin >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/smeadmin/
EOF
#softethernet
rpm -q softethervpn >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/usr/vpnserver/vpn_server.config
/usr/vpnserver/backup.vpn_server.config
/usr/vpnserver/chain_certs
/usr/vpnserver/packet_log
/usr/vpnserver/security_log
/usr/vpnserver/server_log
EOF
#smeserver-sysmon
rpm -q smeserver-sysmon >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/rrd/
EOF
rpm -q smeserver-tftp-server >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/tftpboot
EOF
rpm -q smeserver-transmission >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/transmission/Downloads
EOF
rpm -q smeserver-unifi >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/opt/UniFi
/opt/UniFi_bak
EOF
rpm -q smeserver-xinetd >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/etc/rsyncd.conf
/etc/xinetd.d/rsync
/etc/logrotate.d/rsyncd
EOF
rpm -q smeserver-xt_geoip >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/usr/share/xt_geoip/BE/
/usr/share/xt_geoip/LE/
/var/lib/xt_geoip/
EOF
rpm -q smeserver-webfilter >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/squidGuard/blacklists/
EOF
#smeserver-webshare
rpm -q smeserver-webshare >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/opt/webshare
EOF
# smeserver-zabbix-server smeserver-zabbix-agent smeserver-zabbix-proxy
if [ -d /etc/zabbix ]; then
  for F in /etc/zabbix/*; do
    rpm -qf "$F" >/dev/null 2>&1 || echo "$F" >>dir.list
  done
fi
if [ -d /etc/zabbix/zabbix_agentd.conf.d ]; then
  for F in /etc/zabbix/zabbix_agentd.conf.d/*; do
    rpm -qf "$F" >/dev/null 2>&1 || echo "$F" >>dir.list
  done
fi
if [ -d /var/lib/zabbix/bin ]; then
  for F in /var/lib/zabbix/bin/*; do
    rpm -qf "$F" >/dev/null 2>&1 || echo "$F" >>dir.list
  done
fi
rpm -q smeserver-zoneminder >/dev/null 2>&1 && cat <<'EOF' >>dir.list
/var/lib/zoneminder
/var/log/zoneminder
/var/spool/zoneminder-upload
EOF

#contribs we are aware of, but NOTHING TO DO
#smeserver-email-management
#smeserver-geoip
#smeserver-kronolith
#smeserver-lazy_admin_tools
#smeserver-learn
#smeserver-mailsorting
#smeserver-mailstats
#smeserver-mod_dav
#smeserver-nag
#smeserver-php-fpm
#smeserver-php-scl
#smeserver-phpldapadmin.
#smeserver-phpsysinfo
#smeserver-qmHandle
#smeserver-remoteuseraccess
#smeserver-userpanel
#smeserver-userpanels
#smeserver-vacation
#smeserver-wbl
#smeserver-webapps-common
#smeserver-webhosting
#smeserver-bridge-interface
#smeserver-ddclient
#smeserver-mediatomb
#smeserver-sane
#smeserver-usbdisksmanager

# we might get issue there with .rpmnew files
# but we need to get the same version as in db

#  for F in /usr/share/nextcloud/apps/*;do
#    rpm -qf "$F" >/dev/null 2>&1 || echo "$F" >> dir.list
#  done

/sbin/e-smith/audittools/newrpms >/root/newrpms
cat </root/newrpms | grep @ | cut -d' ' -f1 | sed 's/.noarch//g' | sed 's/.x86_64//g' | sed 's/.i386//g' | sort | grep smeserver >/root/contribs
cat </root/newrpms | grep @ | cut -d' ' -f1 | sed 's/.noarch//g' | sed 's/.x86_64//g' | sed 's/.i386//g' | sort >/root/rpmsextra

mkdir -p /root/migratehelper/{yumDownload,lists}

# Filter out in file per repo

echo "Run through all created files for /root/migratehelper/lists/RpmsPerRepos_*.list"
echo "and"
echo "yum reinstall --downloadonly --downloaddir=/root/migratehelper/yumDownload"
echo "maybe followed by"
echo "yum update --downloadonly --downloaddir=/root/migratehelper/yumDownload"
echo "or"
echo "yum install --downloadonly --downloaddir=/root/migratehelper/yumDownload --installroot=/root/migratehelper/ smeserver-yum --enablerepo=smeos,base --releasever=6"
echo "or after requiring yum-utils  (bug it seems to only download to current dir whatever you do:"
echo "cd /root/migratehelper/yumDownload; yumdownloader install --downloadonly --downloaddir=. smeserver-freepbx -y --disablerepo=* --enablerepo=\$repo --releasever=6"

if [ $TEST = "n" ]; then
  echo "Stopping Services and running backup"

  # uncomment to test Test and prevent backup running
  # echo "Test mode $TEST"
  # exit 1

  #### stop services so no changes occurs
  if [ -e /usr/lib/systemd/system/qmail.service ]; then
    /usr/bin/systemctl stop qmail.service qpsmtpd.service sqpsmtpd.service ejabberd.service smb.service smbd.service nmbd.service httpd-e-smith.service
  else
    sv d /service/qmail
    sv d /service/qpsmtpd
    sv d /service/sqpsmtpd
    [ -e /service/ejabberd ] && sv d /service/ejabberd
    sv d /service/smbd
    sv d /service/httpd-e-smith
  fi
  
  #### prebackup
  signal-event pre-backup

  if [ ! -d /mnt/backup ]; then
    mkdir -p /mnt/backup
  fi

  tar cvzf /mnt/backup/smeserver.tgz -T dir.list --exclude-from exclude.list --xattrs
  echo "Finished. Backup file is in /mnt/backup"
  echo "All services stopped."
  echo "Please copy the remaining excluded files (e.g. /home/e-smith/files/*) to the new server before you halt this server"

else
  echo "Test mode enabled - no backup run"
  echo "Test mode $TEST"
  exit 0
fi

exit 0
