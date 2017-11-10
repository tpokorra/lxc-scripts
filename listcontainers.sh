#!/bin/bash

SCRIPTSPATH=/usr/share/lxc-scripts
if [[ "$0" == "./listcontainers.sh" ]]
then
  SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
fi
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

  if [[ -z "`lxc-ls --running $name`" ]]
  then
    state="stopped"
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

