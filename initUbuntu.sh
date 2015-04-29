#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

if [ -z $2 ]
then
  echo "please call $0 <name of new container> <cid> <release, default is precise> <arch, default is amd64> <autostart, default is 1>"
  echo "   eg. $0 50-ubuntu12.04-mymachine 50"
  exit 1
fi
name=$1
cid=$2
distro="ubuntu"
release="precise"
if [ ! -z $3 ]
then
  release=$3
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

if [[ "$arch" == "amd64" ]]
then
  lxc-create -t download -n $name -- -d $distro -r $release -a $arch || exit 1
else
  lxc-create -n $name -t $distro -- --release=$release --arch=$arch || exit 1
fi

rootfs_path=/var/lib/lxc/$name/rootfs
config_path=/var/lib/lxc/$name
networkfile=${rootfs_path}/etc/network/interfaces
IPv4=10.0.3.$cid
GATEWAY=10.0.3.1

ssh-keygen -f "/root/.ssh/known_hosts" -R $IPv4

#drop the line with 127.0.1.1  $name
cat $rootfs_path/etc/hosts | grep -v $name > $rootfs_path/etc/hosts.new
mv $rootfs_path/etc/hosts.new $rootfs_path/etc/hosts
echo $IPv4 $name >> $rootfs_path/etc/hosts
sed -i 's/^iface eth0 inet.*/iface eth0 inet static/g' $networkfile
echo "lxc.network.ipv4="$IPv4"/24" >> $rootfs_path/../config
echo "lxc.network.ipv4.gateway="$GATEWAY >> $rootfs_path/../config
echo "nameserver "$GATEWAY >> $rootfs_path/etc/resolvconf/resolv.conf.d/head

# mount yum cache repo, to avoid redownloading stuff when reinstalling the machine
hostpath="/var/lib/repocache/$cid/$distro/$release/$arch/var/cache/apt"
~/scripts/initMount.sh $hostpath $name "/var/cache/apt"

# configure timezone
cd $rootfs_path/etc; rm -f localtime; ln -s ../usr/share/zoneinfo/Europe/Berlin localtime; cd -

# install openssh-server
chroot $rootfs_path apt-get update
chroot $rootfs_path apt-get install -y openssh-server

# drop root password completely
chroot $rootfs_path passwd -d root
chroot $rootfs_path passwd -d ubuntu

install_public_keys $rootfs_path

configure_autostart $autostart $rootfs_path

info $cid $name $IPv4

