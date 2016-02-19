#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

show="all"
if [[ "$1" == "running" || "$1" == "stopped" ]]
then
  show=$1
fi

tmpfile=/tmp/listcontainers.txt
echo "--" > $tmpfile
echo -e "Name\t IP\t State\t Autostart\t Guest OS" >> $tmpfile
echo "--" >> $tmpfile
for d in /var/lib/lxc/*
do
  rootfs=$d/rootfs

  if [ ! -d $rootfs ]
  then
    continue
  fi

  name=`basename $d`

  # version=getOSOfContainer
  getOSOfContainer $rootfs

  lxcprocess=`ps xaf | grep "lxc-start" | grep " -n $name" | grep -v grep`
  if [ -z "$lxcprocess" ]
  then
    # on Fedora 22
    lxcprocess=`ps xaf | grep "\[lxc monitor\] /var/lib/lxc $name" | grep -v grep`
    if [ -z "$lxcprocess" ]
    then
      state="stopped"
    else
      state="running"
    fi
  else
    state="running"
  fi

  if [ -z "`cat /var/lib/lxc/$name/config | grep lxc.start.auto | grep 1`" ]
  then
    autostart="no"
  else
    autostart="yes"
  fi

  IPv4=`cat /var/lib/lxc/$name/config | grep "lxc.network.ipv4=" | awk -F= '{ print $2 }' | awk -F/ '{ print $1 }'`

  if [[ "$show" == "all" || "$show" == "$state" ]]
  then
    echo -e $name "\t" $IPv4 "\t" $state "\t" $autostart "\t" $version >> $tmpfile
  fi
done

column -t -s $'\t' $tmpfile
rm -f $tmpfile

