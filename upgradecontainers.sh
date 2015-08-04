#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

echo "updating the host " `hostname -f`
apt-get update && apt-get -y upgrade --force-yes

errors=
for d in /var/lib/lxc/*
do
  container=`basename $d`
  echo
  echo
  echo "======================="
  echo "updating " $container
  echo "======================="
  rootfs=$d/rootfs
  # version,OS,OSRelease=getOSOfContainer
  getOSOfContainer $rootfs
  error=0
  if [[ "$OS" == "CentOS" ]]
  then
    chroot $rootfs bash -c 'yum -y update || exit -1' || error=1
  elif [[ "$OS" == "Fedora" ]]
  then
    if [[ $OSRelease -gt 21 ]]
    then
      chroot $rootfs bash -c 'dnf -y update || exit -1' || error=1
    else
      chroot $rootfs bash -c 'yum -y update || exit -1' || error=1
    fi
  elif [[ "$OS" == "Ubuntu" ]]
  then
    chroot $rootfs bash -c 'apt-get update && apt-get -y upgrade --force-yes || exit -1' || error=1
  elif [[ "$OS" == "Debian" ]]
  then
    chroot $rootfs bash -c 'apt-get update && apt-get -y upgrade --force-yes || exit -1' || error=1
  else
    echo "unknown operating system in container " $container
    exit -1
  fi
  if [ $error -eq 1 ]
  then
    errors="$errorsError upgrading container $container\n"
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
  exit -1
fi
