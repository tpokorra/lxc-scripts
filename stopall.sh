#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

for d in /var/lib/lxc/*
do
  rootfs=$d/rootfs

  if [ ! -d $rootfs ]
  then
    continue
  fi

  name=`basename $d`

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

  if [[ "$state" == "running" ]]
  then
    echo "stopping $name ..."
    lxc-stop -n $name
  fi
done

