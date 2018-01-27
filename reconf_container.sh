#!/bin/bash

# reconfigure a container so that it will run on this host
# eg. when moving a container from an Ubuntu host to CentOS host
# we need to change the name of the bridge, and the network

if [ -z $2 ]; then
  echo "call: $0 cid name"
  echo "eg: $0 3 003-mycontainer.example.org"
  exit
fi

cid=$1
name=$2

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

interface=$(getOutwardInterface)
HostIP=$(getIPOfInterface $interface)
rootfs_path=/var/lib/lxc/$name/rootfs
config_path=/var/lib/lxc/$name
bridgeInterface=$(getBridgeInterface) || die "cannot find the bridge interface"
bridgeAddress=$(getIPOfInterface $bridgeInterface) || die "cannot find the address for the bridge $bridgeInterface"
networkAddress=$(echo $bridgeAddress | cut -f1,2,3 -d".")
IPv4=$networkAddress.$cid

if [ ! -d $rootfs_path ]
then
  echo "cannot find the rootfs " $rootfs_path
  exit
fi

# update the name of the network bridge
sed -i "s/^lxc.network.link = .*/lxc.network.link = $bridgeInterface/g" $config_path/config

# update network address
sed -i "s#^lxc.network.ipv4=.*#lxc.network.ipv4="$IPv4"/24#g" $config_path/config
sed -i "s/^lxc.network.ipv4.gateway=.*/lxc.network.ipv4.gateway="$networkAddress".1/g" $config_path/config

# disable mounts because they are useless if the container has been moved from another host
sed -i "s/^lxc.mount.entry = /#lxc.mount.entry = /g" $config_path/config

getOSOfContainer $rootfs_path

if [[ "$OS" == "CentOS" || "$OS" == "Fedora" ]]; then
  networkfile=${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
  if [ ! -f $networkfile ]
  then
    echo "cannot find the network file " $networkfile
    exit
  fi

  sed -i "s/IPADDR=.*/IPADDR=$IPv4/g" $networkfile
  sed -i "s/GATEWAY=.*/GATEWAY=$bridgeAddress/g" $networkfile
  sed -i "s/NETWORK=.*/NETWORK=$networkAddress.0/g" $networkfile

  resolvfile=${rootfs_path}/etc/resolv.conf

  if [ ! -f $resolvfile ]
  then
    echo "cannot find the resolv file " $resolvfile
    exit
  fi

  echo "nameserver $bridgeAddress" >  $resolvfile
fi

if [[ "$OS" == "Debian" || "$OS" == "Ubuntu" ]]; then
  hostfile=${rootfs_path}/etc/hosts

  if [ ! -f $hostfile ]; then
    echo "cannot find the host file " $hostfile
    exit
  fi

  sed -i "s/.* $name/$IPv4 $name/g" $hostfile
fi

if [[ "$OS" == "Ubuntu" ]]; then
  resolvfile=${rootfs_path}/etc/resolvconf/resolv.conf.d/head

  if [ ! -f $resolvfile ]
  then
    echo "cannot find the resolv file " $resolvfile
    exit
  fi

  echo "nameserver $bridgeAddress" >  $resolvfile
fi

echo "done."
echo "You may now start the container!"
