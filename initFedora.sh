#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

if [ -z $2 ]
then
  echo "please call $0 <name of new container> <cid> <release, default is 27> <arch, default is amd64> <autostart, default is 1>"
  echo "   eg. $0 50-fedora-mymachine 50"
  exit 1
fi
name=$1
cid=$2
distro="fedora"
release="27"
if [ ! -z $3 ]
then
  if [[ "$3" != "rawhide" ]]
  then
    release=$3
  fi
fi
arch="amd64"
if [ ! -z $4 ]
then
  arch=$4
fi
autostart=1
if [ ! -z $5 ]
then
  autostart=$5
fi

rootfs_path=/var/lib/lxc/$name/rootfs
config_path=/var/lib/lxc/$name
networkfile=${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
bridgeInterface=$(getBridgeInterface)
bridgeAddress=$(getIPOfInterface $bridgeInterface)
networkAddress=$(echo $bridgeAddress | awk -F '.' '{ print $1"."$2"."$3 }')
IPv4=$networkAddress.$cid

if [ $release -ge 28 ]
then
  if [[ "$arch" == "amd64" ]]
  then
    arch="x86_64"
  fi
  # there is no template available at https://jenkins.linuxcontainers.org/view/LXC/view/LXC%20templates/job/lxc-template-fedora/
  LANG=C lxc-create -t fedora -n $name -- -R $release -a $arch || exit 1
else
  lxc-create -t download -n $name -- -d $distro -r $release -a $arch || exit 1
fi

ssh-keygen -f "/root/.ssh/known_hosts" -R $IPv4

if [ ! -f $rootfs_path/etc/sysconfig/network ]
then
  cat > $rootfs_path/etc/sysconfig/network << FINISH
NETWORKING=yes
HOSTNAME=$name
BOOTPROTO=static
FINISH
else
  sed -i "s/HOSTNAME=.*/HOSTNAME=$name/g" $rootfs_path/etc/sysconfig/network
fi

if [[ "$http_proxy" != "" ]]
then
  proxyhostandport=`echo $http_proxy | awk -F/ '{ print $3 }' | awk -F@ '{ print $2 }'`
  proxyuser=`echo $http_proxy | awk -F/ '{ print $3 }' | awk -F@ '{ print $1 }' | awk -F: '{ print $1 }'`
  proxypwd=`echo $http_proxy | awk -F/ '{ print $3 }' | awk -F@ '{ print $1 }' | awk -F: '{ print $2 }'`
  echo "proxy=http://$proxyhostandport" >> $rootfs_path/etc/dnf/dnf.conf
  echo "proxy_username=$proxyuser" >> $rootfs_path/etc/dnf/dnf.conf
  echo "proxy_password=$proxypwd" >> $rootfs_path/etc/dnf/dnf.conf
fi


if [ ! -f $networkfile ]
then
  cat > $networkfile << FINISH
DEVICE=eth0
BOOTPROTO=static
ONBOOT=yes
HOSTNAME=`hostname`
DHCP_HOSTNAME=`hostname`
NM_CONTROLLED=no
TYPE=Ethernet
MTU=
IPADDR=$IPv4
GATEWAY=$bridgeAddress
NETMASK=255.255.255.0
NETWORK=$networkAddress.0
DNS1=$bridgeAddress
FINISH
else
  sed -i 's/^BOOTPROTO=*/BOOTPROTO=static/g' $networkfile
  echo "IPADDR=$IPv4" >> $networkfile
  echo "GATEWAY=$bridgeAddress" >> $networkfile
  echo "NETMASK=255.255.255.0" >> $networkfile
  echo "NETWORK=$networkAddress.0" >> $networkfile
  echo "DNS1=$bridgeAddress" >>  $networkfile
fi

sed -i "s/lxc.network.link = lxcbr0/lxc.network.link = $bridgeInterface/g" $rootfs_path/../config
echo "lxc.network.ipv4="$IPv4"/24" >> $rootfs_path/../config
# fix a problem with AppArmor. otherwise you get a SEGV
echo "lxc.aa_profile = unconfined" >> $rootfs_path/../config
# fix a problem with seccomp. Machine does not start otherwise
echo "lxc.seccomp =" >> $rootfs_path/../config
# fix some problems with journald
echo "lxc.kmsg = 0" >> $rootfs_path/../config
echo "lxc.autodev = 1" >> $rootfs_path/../config
echo "lxc.cap.drop = mknod" >> $rootfs_path/../config

echo "127.0.0.1 "$name" localhost" > $rootfs_path/etc/hosts

# mount yum cache repo, to avoid redownloading stuff when reinstalling the machine
hostpath="/var/lib/repocache/$cid/$distro/$release/$arch/var/cache/yum"
$SCRIPTSPATH/initMount.sh $hostpath $name "/var/cache/yum"

# configure timezone
cd $rootfs_path/etc; rm -f localtime; ln -s ../usr/share/zoneinfo/Europe/Berlin localtime; cd -

# dnf: keep the cache
sed -i 's/^keepcache=0/keepcache=1/g' $rootfs_path/etc/dnf/dnf.conf

# use default locale
echo "export LANG=C" >> $rootfs_path/etc/profile

# install openssh-server
lxc-start -d -n $name

# need to wait after start, otherwise dnf will not get a connection
sleep 10

lxc-attach -n $name --keep-env -- dnf -y install openssh-server

if [ $release -ge 24 ]
then
  # need to install the locales
  lxc-attach -n $name --keep-env -- dnf -y install glibc-locale-source glibc-all-langpacks
fi

lxc-stop -n $name

# drop root password completely
chroot $rootfs_path passwd -d root
# disallow auth with null password
sed -i 's/nullok//g' $rootfs_path/etc/pam.d/system-auth

install_public_keys $rootfs_path

configure_autostart $autostart $rootfs_path

info $cid $name $IPv4

