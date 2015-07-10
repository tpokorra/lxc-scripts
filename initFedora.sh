#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

if [ -z $2 ]
then
  echo "please call $0 <name of new container> <cid> <release, default is 22> <arch, default is amd64> <autostart, default is 1>"
  echo "   eg. $0 50-fedora-mymachine 50"
  exit 1
fi
name=$1
cid=$2
distro="fedora"
release="22"
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

if [[ "$release" == "21" || "$release" == "22" ]]
then
  if [[ "$arch" == "amd64" ]]
  then
    arch="x86_64"
  fi
  # there is no template available at https://jenkins.linuxcontainers.org/view/LXC/view/LXC%20Templates/job/lxc-template-fedora/
  lxc-create -t fedora -n $name -- -R $release -a $arch || exit 1
else
  lxc-create -t download -n $name -- -d $distro -r $release -a $arch || exit 1
fi

rootfs_path=/var/lib/lxc/$name/rootfs
config_path=/var/lib/lxc/$name
networkfile=${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
bridgeInterface=$(getBridgeInterface)
bridgeAddress=$(getIPOfInterface $bridgeInterface)
networkAddress=$(echo $bridgeAddress | awk -F '.' '{ print $1"."$2"."$3 }')
IPv4=$networkAddress.$cid

ssh-keygen -f "/root/.ssh/known_hosts" -R $IPv4

sed -i "s/HOSTNAME=.*/HOSTNAME=$name/g" $rootfs_path/etc/sysconfig/network
sed -i 's/^BOOTPROTO=*/BOOTPROTO=static/g' $networkfile
echo "IPADDR=$IPv4" >> $networkfile
echo "GATEWAY=$bridgeAddress" >> $networkfile
echo "NETMASK=255.255.255.0" >> $networkfile
echo "NETWORK=$networkAddress.0" >> $networkfile
echo "nameserver $bridgeAddress" >  $rootfs_path/etc/resolv.conf
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

# yum: keep the cache
sed -i 's/^keepcache=0/keepcache=1/g' $rootfs_path/etc/yum.conf

# install openssh-server
chroot $rootfs_path yum -y install openssh-server

# drop root password completely
chroot $rootfs_path passwd -d root

install_public_keys $rootfs_path

configure_autostart $autostart $rootfs_path

info $cid $name $IPv4

