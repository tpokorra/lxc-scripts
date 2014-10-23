#!/bin/bash

for d in /var/lib/lxc/*
do
  rootfs=$d/rootfs
  if [ -f $rootfs/etc/redhat-release ]
  then
    # CentOS
    echo -e `basename $d` "\t" `cat $rootfs/etc/redhat-release`
  elif [ -f $rootfs/etc/lsb-release ]
  then
    # Ubuntu
    . $rootfs/etc/lsb-release
    echo -e `basename $d` "\t" $DISTRIB_DESCRIPTION
  elif [ -f $rootfs/etc/debian_version ]
  then
    # Debian
    echo -e `basename $d` "\tDebian" `cat $rootfs/etc/debian_version`
  fi
  
done
