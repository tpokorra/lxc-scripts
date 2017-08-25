#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

if [ -z "$2" ]
then
  echo "optional: can pass sender and recipient email address to send an email when there are update errors"
  echo "sample call: $0 errors@example.org admin@example.org"
  echo
fi
errorsSender=$1
errorsRecipient=$2

echo "updating the host " `hostname -f`
apt-get update && apt-get -y upgrade --force-yes

errors=
for d in /var/lib/lxc/*
do
  container=`basename $d`

  # if the container does not have autostart enabled, don't upgrade it
  # we don't want to upgrade temporary or development containers
  if [ -z "`cat /var/lib/lxc/$container/config | grep lxc.start.auto | grep 1`" ]
  then
    continue
  fi

  # lxc 1.x
  lxcprocess=`ps xaf | grep "lxc-start" | grep " -n $container" | grep -v grep`
  if [ -z "$lxcprocess" ]
  then
    # lxc 2.x
    lxcprocess=`ps xaf | grep "lxc $container" | grep -v grep`
    if [ -z "$lxcprocess" ]
    then
      # stopped. do not upgrade, potential problems with mysql updates etc.
      continue
    fi
  fi

  echo
  echo
  echo "======================="
  echo "updating " $container
  echo "======================="
  rootfs=$d/rootfs
  # version,OS,OSRelease=getOSOfContainer
  getOSOfContainer $rootfs
  name=`basename $d`
  error=0
  if [[ "$OS" == "CentOS" ]]
  then
    (lxc-attach -n $name -- yum -y update ) || error=1
  elif [[ "$OS" == "Fedora" ]]
  then
    (lxc-attach -n $name -- dnf -y update ) || error=1
  elif [[ "$OS" == "Ubuntu" ]]
  then
    chroot $rootfs bash -c 'LANG=C; apt-get update && apt-get -y upgrade --force-yes || exit -1' || error=1
  elif [[ "$OS" == "Debian" ]]
  then
    chroot $rootfs bash -c 'LANG=C; apt-get update && apt-get -y upgrade --force-yes || exit -1' || error=1
  else
    echo "unknown operating system in container " $container
    exit -1
  fi
  if [ $error -eq 1 ]
  then
    errors="${errors}Error upgrading container $container\n"
  fi
done

if [ ! -z "$errors" ]
then
  echo
  echo
  echo "=============================="
  echo "problems upgrading containers:"
  echo "=============================="
  echo -e $errors

  if [ ! -z "$errorsRecipient" ]
  then
    getOSOfContainer "/"
    if [[ "$OS" == "CentOS" ]]
    then
      echo -e "problems upgrading containers on host `hostname -f`: \n $errors" | mail -s "problems upgrading containers on host `hostname -f`" -a "From: $errorsSender" "$errorsRecipient"
    elif [[ "$OS" == "Ubuntu" ]]
    then
      echo -e "problems upgrading containers on host `hostname -f`: \n $errors" | mail -s "problems upgrading containers on host `hostname -f`" -r $errorsSender "$errorsRecipient"
    fi
  fi

  exit -1
fi
