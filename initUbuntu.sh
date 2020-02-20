#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

distro="ubuntu"
release="bionic"

if [ -z $2 ]
then
  echo "please call $0 <name of new container> <cid> <release, default is $release> <arch, default is amd64> <autostart, default is 1>"
  echo "   eg. $0 50-ubuntu-mymachine 50"
  exit 1
fi
name=$1
cid=$2
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

rootfs_path=/var/lib/lxc/$name/rootfs
config_path=/var/lib/lxc/$name
networkfile=${rootfs_path}/etc/network/interfaces
bridgeInterface=$(getBridgeInterface)
bridgeAddress=$(getIPOfInterface $bridgeInterface)
networkAddress=$(echo $bridgeAddress | awk -F '.' '{ print $1"."$2"."$3 }')
IPv4=$networkAddress.$cid

if [ ! -f /usr/share/keyrings/ubuntu-archive-keyring.gpg ]
then
  mkdir -p /usr/share/keyrings
  wget http://archive.ubuntu.com/ubuntu/project/ubuntu-archive-keyring.gpg -O /usr/share/keyrings/ubuntu-archive-keyring.gpg
fi
lxc-create -t ubuntu -n $name -- --release=$release --arch=$arch || exit 1

ssh-keygen -f "/root/.ssh/known_hosts" -R $IPv4

#drop the line with 127.0.1.1  $name
cat $rootfs_path/etc/hosts | grep -v $name > $rootfs_path/etc/hosts.new
mv $rootfs_path/etc/hosts.new $rootfs_path/etc/hosts
echo $IPv4 $name >> $rootfs_path/etc/hosts
if [ -f $networkfile ]; then
  sed -i 's/^iface eth0 inet.*/iface eth0 inet static/g' $networkfile
fi
networkfile=$rootfs_path/etc/netplan/10-lxc.yaml
if [ -f $networkfile ]; then
  sed -i "s#eth0:.*#eth0: { dhcp4: no, addresses: [$IPv4/24], gateway4: $bridgeAddress, nameservers: {addresses: [$bridgeAddress] }}#g" $networkfile
fi

network="lxc.network"
if [ -z "`cat $rootfs_path/../config | grep "$network.link"`" ]
then
  # lxc 3
  network="lxc.net.0"
fi

sed -i "s/$network.link = lxcbr0/$network.link = $bridgeInterface/g" $rootfs_path/../config
if [[ "$network" == "lxc.network" ]]; then
  echo "$network.ipv4="$IPv4"/24" >> $rootfs_path/../config
else
  echo "$network.ipv4.address = "$IPv4"/24" >> $rootfs_path/../config
fi
echo "$network.ipv4.gateway="$bridgeAddress >> $rootfs_path/../config
if [ -f $rootfs_path/etc/resolv.conf ]; then
  cat "nameserver "$bridgeAddress >> $rootfs_path/etc/resolv.conf
else
  echo "nameserver "$bridgeAddress >> $rootfs_path/etc/resolvconf/resolv.conf.d/head
fi

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

