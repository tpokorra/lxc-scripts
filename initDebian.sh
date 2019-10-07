#!/bin/bash
SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

distro="debian"
release="buster"

if [ -z $2 ]
then
  echo "please call $0 <name of new container> <cid> <release, default is $release> <arch, default is amd64> <autostart, default is 1>"
  echo "   eg. $0 50-debian-mymachine 50"
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
resolvfile=${rootfs_path}/etc/resolv.conf
bridgeInterface=$(getBridgeInterface)
bridgeAddress=$(getIPOfInterface $bridgeInterface)
networkAddress=$(echo $bridgeAddress | awk -F '.' '{ print $1"."$2"."$3 }')
IPv4=$networkAddress.$cid

lxc-create -t download -n $name -- -d $distro -r $release -a $arch || exit 1

ssh-keygen -f "/root/.ssh/known_hosts" -R $IPv4

echo $IPv4 $name >> $rootfs_path/etc/hosts
sed -i 's/^iface eth0 inet.*/iface eth0 inet static/g' $networkfile
echo "nameserver $bridgeAddress" > $resolvfile
sed -i "s/lxc.net.0.link = lxcbr0/lxc.net.0.link = $bridgeInterface/g" $rootfs_path/../config
echo "lxc.net.0.ipv4.address = "$IPv4"/24" >> $rootfs_path/../config
echo "lxc.net.0.ipv4.gateway = "$bridgeAddress >> $rootfs_path/../config

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

# mount apt cache repo, to avoid redownloading stuff when reinstalling the machine
hostpath="/var/lib/repocache/$cid/$distro/$release/$arch/var/cache/apt"
$SCRIPTSPATH/initMount.sh $hostpath $name "/var/cache/apt"

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
