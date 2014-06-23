#!/bin/bash

if [ -z $2 ]
then
  echo "please call $0 <name of new container> <cid>"
  echo "   eg. $0 50-debian7-mymachine 50"
  exit 1
fi
name=$1
cid=$2

lxc-create -t download -n $name -- -d debian -r wheezy -a amd64

rootfs_path=/var/lib/lxc/$name/rootfs
config_path=/var/lib/lxc/$name
IPv4=10.0.3.$cid

echo $IPv4 $name >> $rootfs_path/etc/hosts
echo "lxc.network.ipv4="$IPv4"/24" >> $rootfs_path/../config

# configure timezone
cd $rootfs_path/etc; rm -f localtime; ln -s ../usr/share/zoneinfo/Europe/Berlin localtime; cd -

# setup port forwarding from outside
./tunnelssh.sh $name $cid

# make sure the container starts at next boot time
echo "lxc.start.auto = 1" >> $rootfs_path/../config
echo "lxc.start.delay = 5" >> $rootfs_path/../config

