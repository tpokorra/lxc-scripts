#!/bin/bash

function install_public_keys {
rootfs_path=$1

  # install the public keys for the host machine to the container as well
  mkdir -p $rootfs_path/root/.ssh
  cat /root/.ssh/authorized_keys >> $rootfs_path/root/.ssh/authorized_keys
  chmod -R 600 $rootfs_path/root/.ssh/authorized_keys

  # install the public key for local root login
  if [ -f /root/.ssh/id_rsa.pub ]
  then
    cat /root/.ssh/id_rsa.pub >> $rootfs_path/root/.ssh/authorized_keys
    chmod -R 600 $rootfs_path/root/.ssh/authorized_keys
  fi
}

function configure_autostart {
autostart=$1
rootfs_path=$2

  if [ $autostart -eq 1 ]
  then
    # make sure the container starts at next boot time
    echo "lxc.start.auto = 1" >> $rootfs_path/../config
    echo "lxc.start.delay = 5" >> $rootfs_path/../config
  fi
}

function info {
cid=$1
name=$2
IPv4=$3

  echo To setup port forwarding from outside, please run:
  echo ./tunnelport.sh $cid 22
  echo ./initWebproxy.sh $cid www.$name.de
  echo
  echo To start the container, run: lxc-start -d -n $name
  echo
  echo "To connect to the container locally, run: eval \`ssh-agent\`; ssh-add; ssh root@$IPv4"

}
