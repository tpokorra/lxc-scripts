#!/bin/bash

for d in /var/lib/lxc/*
do
  rootfs=$d/rootfs
  name=`basename $d`
  if [ -f $rootfs/etc/redhat-release ]
  then
    # CentOS
    version="`cat $rootfs/etc/redhat-release`"
  elif [ -f $rootfs/etc/lsb-release ]
  then
    # Ubuntu
    . $rootfs/etc/lsb-release
    version="$DISTRIB_DESCRIPTION"
  elif [ -f $rootfs/etc/debian_version ]
  then
    # Debian
    version="Debian `cat $rootfs/etc/debian_version`"
  fi

  if [ -z "`ps xaf | grep "lxc-start -d -n $name" | grep -v grep`" ]
  then
    state="stopped"
  else
    state="running"
  fi

  if [ -z "`cat /var/lib/lxc/$name/config | grep lxc.start.auto | grep 1`" ]
  then
    autostart="yes"
  else
    autostart="no"
  fi

  IPv4=`cat /var/lib/lxc/$name/config | grep "lxc.network.ipv4=" | awk -F= '{ print $2 }' | awk -F/ '{ print $1 }'`
  
  echo -e $name "\t" $IPv4 "\t" $state "\t" $autostart "\t" $version
done

