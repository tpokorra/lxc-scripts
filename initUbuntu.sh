#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

if [ -z $2 ]
then
  echo "please call $0 <name of new container> <cid> <release, default is trusty> <arch, default is amd64> <autostart, default is 1>"
  echo "   eg. $0 50-ubuntu-mymachine 50"
  exit 1
fi
name=$1
cid=$2
distro="ubuntu"
release="trusty"
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

if [ ! -f /usr/share/keyrings/ubuntu-archive-keyring.gpg ]
then
  mkdir -p /usr/share/keyrings
  wget http://archive.ubuntu.com/ubuntu/project/ubuntu-archive-keyring.gpg -O /usr/share/keyrings/ubuntu-archive-keyring.gpg
fi
lxc-create -t ubuntu -n $name -- --release=$release --arch=$arch || exit 1

rootfs_path=/var/lib/lxc/$name/rootfs
config_path=/var/lib/lxc/$name
networkfile=${rootfs_path}/etc/network/interfaces
bridgeInterface=$(getBridgeInterface)
bridgeAddress=$(getIPOfInterface $bridgeInterface)
networkAddress=$(echo $bridgeAddress | awk -F '.' '{ print $1"."$2"."$3 }')
IPv4=$networkAddress.$cid

ssh-keygen -f "/root/.ssh/known_hosts" -R $IPv4

#drop the line with 127.0.1.1  $name
cat $rootfs_path/etc/hosts | grep -v $name > $rootfs_path/etc/hosts.new
mv $rootfs_path/etc/hosts.new $rootfs_path/etc/hosts
echo $IPv4 $name >> $rootfs_path/etc/hosts
sed -i 's/^iface eth0 inet.*/iface eth0 inet static/g' $networkfile
sed -i "s/lxc.network.link = lxcbr0/lxc.network.link = $bridgeInterface/g" $rootfs_path/../config
echo "lxc.network.ipv4="$IPv4"/24" >> $rootfs_path/../config
echo "lxc.network.ipv4.gateway="$bridgeAddress >> $rootfs_path/../config
echo "nameserver "$bridgeAddress >> $rootfs_path/etc/resolvconf/resolv.conf.d/head

# mount yum cache repo, to avoid redownloading stuff when reinstalling the machine
hostpath="/var/lib/repocache/$cid/$distro/$release/$arch/var/cache/apt"
$SCRIPTSPATH/initMount.sh $hostpath $name "/var/cache/apt"

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

