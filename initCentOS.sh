#!/bin/bash

if [ -z $2 ]
then
  echo "please call $0 <name of new container> <cid> <release, default is 6> <arch, default is amd64> <autostart, default is 1>"
  echo "   eg. $0 50-centos6-mymachine 50"
  exit 1
fi
name=$1
cid=$2
distro="centos"
release="6"
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

lxc-create -t download -n $name -- -d $distro -r $release -a $arch

rootfs_path=/var/lib/lxc/$name/rootfs
config_path=/var/lib/lxc/$name
networkfile=${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
IPv4=10.0.3.$cid

sed -i "s/HOSTNAME=.*/HOSTNAME=$name/g" $rootfs_path/etc/sysconfig/network
sed -i 's/^BOOTPROTO=*/BOOTPROTO=static/g' $networkfile
echo "IPADDR=$IPv4" >> $networkfile
echo "GATEWAY=10.0.3.1" >> $networkfile
echo "NETMASK=255.255.255.0" >> $networkfile
echo "NETWORK=10.0.3.0" >> $networkfile
echo "nameserver 10.0.3.1" >  $rootfs_path/etc/resolv.conf
echo "lxc.network.ipv4="$IPv4"/24" >> $rootfs_path/../config
echo "lxc.mount.entry = tmpfs " rootfs_path "/dev/shm tmpfs defaults 0 0" >> $rootfs_path/../config

# mount yum cache repo, to avoid redownloading stuff when reinstalling the machine
hostpath="/var/lib/repocache/$cid/$distro/$release/$arch/var/cache/yum"
if [ ! -d $hostpath ]
then
  mkdir -p $hostpath
fi
containerpath="$rootfs_path/var/cache/yum"
if [ ! -d $containerpath ]
then
  mkdir -p $containerpath
fi
echo "lxc.mount.entry = $hostpath $containerpath none defaults,bind 0 0" >> $rootfs_path/../config

# configure timezone
cd $rootfs_path/etc; rm -f localtime; ln -s ../usr/share/zoneinfo/Europe/Berlin localtime; cd -

# yum: keep the cache
sed -i 's/^keepcache=0/keepcache=1/g' $rootfs_path/etc/yum.conf

if [ $autostart -eq 1 ]
then
  # make sure the container starts at next boot time
  echo "lxc.start.auto = 1" >> $rootfs_path/../config
  echo "lxc.start.delay = 5" >> $rootfs_path/../config

  echo To setup port forwarding from outside, please run:
  echo ./tunnelssh.sh $name $cid
  echo ./initWebproxy.sh $name $cid www.$name.de
else
  # reset the password
  chroot $rootfs_path passwd -d root
fi



