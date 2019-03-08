#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh
# version,OS,OSRelease=getOSOfContainer
getOSOfContainer /

# There is a problem with Fedora containers, that systemd cannot be upgraded inside the container.
# fix for LXC 1.x
sed -i "s/^lxc.cap.drop = setfcap$/#lxc.cap.drop = setfcap/g" /usr/share/lxc/config/fedora.common.conf
# fix for LXC 2.x
sed -i "s/^lxc.cap.drop = setfcap /lxc.cap.drop = /g" /usr/share/lxc/config/fedora.common.conf

# fix a problem for CentOS7 containers. see https://github.com/lxc/lxc/commit/a4aed378f802ad9caf74ee1c20dc74a6f9d7ca17
# also remove setfcap, see https://bugzilla.redhat.com/show_bug.cgi?id=648654#c31 (httpd did not install for Kolab on CentOS7)
sed -i "s/^lxc.cap.drop = mac_admin mac_override setfcap setpcap/lxc.cap.drop = mac_admin mac_override/g" /usr/share/lxc/config/centos.common.conf
sed -i "s/^lxc.cap.drop = mac_admin mac_override setfcap/lxc.cap.drop = mac_admin mac_override/g" /usr/share/lxc/config/centos.common.conf

# create a key pair for ssh into the container as root
if [ ! -f /root/.ssh/id_rsa ]
then
  ssh-keygen -t rsa -C "root@localhost"
fi

# create a new, unique Diffie-Hellman group, to fight the Logjam attack: https://weakdh.org/sysadmin.html
if [ ! -f /var/lib/certs/dhparams.pem ]
then
  mkdir -p /var/lib/certs
  openssl dhparam -out /var/lib/certs/dhparams.pem 2048
fi

# install a cronjob that checks the expiry date of ssl certificates and installs a new letsencrypt certificate
if [ ! -f /etc/cron.d/letsencrypt ]
then
  echo "5 8 * * 6 root PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin cd /usr/share/lxc-scripts && ./letsencrypt.sh all" > /etc/cron.d/letsencrypt
fi

if [ ! -f /usr/bin/lc -a -f /usr/share/lxc-scripts/listcontainers.sh ]
then
  ln -s /usr/share/lxc-scripts/listcontainers.sh /usr/bin/lc
fi

if [[ "$OS" == "CentOS" || "$OS" == "Fedora" ]]
then
  if [[ "$OS" == "CentOS" && "$OSRelease" -lt 7 ]]
  then
    service crond start
    chkconfig crond on
  else
    systemctl enable crond || exit -1
    systemctl start crond || exit -1
  fi
elif [[ "$OS" == "Debian" || "$OS" == "Ubuntu" ]]
then
  if [[ "$OS" == "Debian" && $OSRelease -ge 8 ]]
  then
    systemctl enable cron || exit -1
    systemctl start cron || exit -1
  else
    service cron start
    update-rc.d cron defaults
  fi
fi
