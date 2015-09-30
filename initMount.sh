#!/bin/bash

if [ -z $3 ]
then
  echo "please call $0 <hostpath> <containername> <localpath>"
  exit 1
fi

hostpath=$1
containername=$2
localpath=$3
relativepath=$containername/rootfs$localpath
containerpath=/var/lib/lxc/$relativepath

mkdir -p $hostpath
rm -Rf $containerpath
mkdir -p $containerpath

echo "lxc.mount.entry = $hostpath $relativepath none defaults,bind 0 0" >> /var/lib/lxc/$containername/config

