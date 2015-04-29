#!/bin/bash

source lib.sh

if [ -z $2 ]
then
  echo "please call $0 <name of new container> <cid> <release, default is wheezy> <arch, default is amd64> <autostart, default is 1>"
  echo "   eg. $0 50-debian7-mymachine 50"
  exit 1
fi
name=$1
cid=$2
distro="debian"
release="wheezy"
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

lxc-create -t download -n $name -- -d $distro -r $release -a $arch || exit 1

rootfs_path=/var/lib/lxc/$name/rootfs
config_path=/var/lib/lxc/$name
networkfile=${rootfs_path}/etc/network/interfaces
IPv4=10.0.3.$cid
GATEWAY=10.0.3.1

ssh-keygen -f "/root/.ssh/known_hosts" -R $IPv4

echo $IPv4 $name >> $rootfs_path/etc/hosts
sed -i 's/^iface eth0 inet.*/iface eth0 inet static/g' $networkfile
echo "lxc.network.ipv4="$IPv4"/24" >> $rootfs_path/../config
echo "lxc.network.ipv4.gateway="$GATEWAY >> $rootfs_path/../config

if [ "$release" == "jessie" ]
then
  echo "lxc.aa_profile = unconfined" >> $rootfs_path/../config

  # see http://serverfault.com/questions/658052/systemd-journal-in-debian-jessie-lxc-container-eats-100-cpu
  echo "lxc.kmsg = 0" >> $rootfs_path/../config
  sed -i "s/ConditionPathExists/#ConditionPathExists/g" $rootfs_path/lib/systemd/system/getty@.service
  # see https://wiki.archlinux.org/index.php/Lxc-systemd
  echo "lxc.autodev = 1" >> $rootfs_path/../config

  echo "lxc.cap.drop = mknod" >> $rootfs_path/../config
fi

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

install_public_keys $rootfs_path

configure_autostart $autostart $rootfs_path

info $cid $name $IPv4
