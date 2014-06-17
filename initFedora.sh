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

sed -i "s/HOSTNAME=.*/HOSTNAME=$name/g" $rootfs_path/etc/sysconfig/network
sed -i "s/^#lxc\.network\.ipv4.*/lxc.network.ipv4=10.0.3.$cid/g" $config_path/config
sed -i 's/^BOOTPROTO=dhcp/#BOOTPROTO=dhcp/g' ${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
sed -i 's/^#BOOTPROTO=none/BOOTPROTO=none/g' ${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
sed -i "s/^#IPADDR/IPADDR/g" ${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
sed -i 's/^#GATEWAY/GATEWAY/g' ${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
sed -i 's/^#NETMASK/NETMASK/g' ${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
sed -i 's/^#NETWORK/NETWORK/g' ${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
sed -i "s/^IPADDR.*/IPADDR=10.0.3.$cid/g" ${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
sed -i 's/^GATEWAY.*/GATEWAY=10.0.3.1/g' ${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
sed -i 's/^NETMASK.*/NETMASK=255.255.255.0/g' ${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
sed -i 's/^NETWORK.*/NETWORK=10.0.3.0/g' ${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
sed -i 's/^DHCP_HOSTNAME/#DHCP_HOSTNAME/g' ${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
./tunnelssh.sh $name $cid
cd $rootfs_path/etc; rm localtime; ln -s ../usr/share/zoneinfo/Europe/Berlin localtime; cd -
