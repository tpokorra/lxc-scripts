#!/bin/bash

if [ -z $2 ]
then
  echo "please call $0 <name of new container> <cid>"
  echo "   eg. $0 50-centos6-mymachine 50"
  exit 1
fi
name=$1
cid=$2

lxc-create -t download -n $name -- -d fedora -r 20 -a amd64

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

# configure timezone
cd $rootfs_path/etc; rm -f localtime; ln -s ../usr/share/zoneinfo/Europe/Berlin localtime; cd -

# yum: keep the cache
sed -i 's/^keepcache=0/keepcache=1/g' $rootfs_path/etc/yum.conf

./tunnelssh.sh $name $cid
cd $rootfs_path/etc; rm localtime; ln -s ../usr/share/zoneinfo/Europe/Berlin localtime; cd -
