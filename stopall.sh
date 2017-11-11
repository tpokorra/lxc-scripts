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

  if [[ -z "`lxc-ls --running $name`" ]]
  then
    state="stopped"
  else
    state="running"
  fi

  if [[ "$state" == "running" ]]
  then
    echo "stopping $name ..."
    lxc-attach -n $name -- poweroff
  fi
done

