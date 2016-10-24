#!/bin/bash

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

if [ -z $2 ]
then
  echo "please call $0 <name of new container> <cid> <release, default is 7> <arch, default is amd64> <autostart, default is 1>"
  echo "   eg. $0 50-centos-mymachine 50"
  exit 1
fi
name=$1
cid=$2
distro="centos"
release="7"
if [ ! -z $3 ]
then
  release=$3
fi
arch="amd64"
if [ ! -z $4 ]
then
  arch=$4
fi
autostart=1
if [ ! -z $5 ]
then
  autostart=$5
fi

rootfs_path=/var/lib/lxc/$name/rootfs
config_path=/var/lib/lxc/$name
networkfile=${rootfs_path}/etc/sysconfig/network-scripts/ifcfg-eth0
bridgeInterface=$(getBridgeInterface) || die "cannot find the bridge interface"
bridgeAddress=$(getIPOfInterface $bridgeInterface) || die "cannot find the address for the bridge $bridgeInterface"
networkAddress=$(echo $bridgeAddress | cut -f1,2,3 -d".")
IPv4=$networkAddress.$cid

if ( [ "$release" == "5" ] ) || ( [ "$release" == "7" ] && [ "$arch" == "i686" ] )
then
  if [ -z `which yum` ]
  then
    echo "please activate the universe repository and run: apt-get install yum"
    exit -1
  fi
  arch2=$arch
  if [ "$arch" == "amd64" ]
  then
    arch2="x86_64"
  fi
  if ( [ "$release" == "7" ] && [ "$arch" == "i686" ] )
  then
    lxc-create -n $name -t $distro -- --repo=http://mirror.centos.org/altarch/7/os/i386/ --release=$release --arch=i686 || exit 1
  else
    lxc-create -n $name -t $distro -- --release=$release --arch=$arch2 || exit 1
  fi
else
  lxc-create -t download -n $name -- -d $distro -r $release -a $arch || exit 1
fi

ssh-keygen -f "/root/.ssh/known_hosts" -R $IPv4

sed -i "s/HOSTNAME=.*/HOSTNAME=$name/g" $rootfs_path/etc/sysconfig/network
sed -i 's/^BOOTPROTO=*/BOOTPROTO=static/g' $networkfile
echo "IPADDR=$IPv4" >> $networkfile
echo "GATEWAY=$bridgeAddress" >> $networkfile
echo "NETMASK=255.255.255.0" >> $networkfile
echo "NETWORK=$networkAddress.0" >> $networkfile
echo "nameserver $bridgeAddress" >  $rootfs_path/etc/resolv.conf
sed -i "s/lxc.network.link = lxcbr0/lxc.network.link = $bridgeInterface/g" $rootfs_path/../config
echo "lxc.network.ipv4="$IPv4"/24" >> $rootfs_path/../config
#echo "lxc.network.ipv4.gateway=$networkaddress.1" >> $rootfs_path/../config
echo "127.0.0.1 "$name" localhost" > $rootfs_path/etc/hosts

if [ "$release" == "7" ]
then
  echo "lxc.aa_profile = unconfined" >> $rootfs_path/../config

  # see http://serverfault.com/questions/658052/systemd-journal-in-debian-jessie-lxc-container-eats-100-cpu
  echo "lxc.kmsg = 0" >> $rootfs_path/../config
  sed -i "s/ConditionPathExists/#ConditionPathExists/g" $rootfs_path/lib/systemd/system/getty@.service
  # see https://wiki.archlinux.org/index.php/Lxc-systemd
  echo "lxc.autodev = 1" >> $rootfs_path/../config
fi

# mount yum cache repo, to avoid redownloading stuff when reinstalling the machine
hostpath="/var/lib/repocache/$cid/$distro/$release/$arch/var/cache/yum"
$SCRIPTSPATH/initMount.sh $hostpath $name "/var/cache/yum"

# configure timezone
cd $rootfs_path/etc; rm -f localtime; ln -s ../usr/share/zoneinfo/Europe/Berlin localtime; cd -

# yum: keep the cache
sed -i 's/^keepcache=0/keepcache=1/g' $rootfs_path/etc/yum.conf

if [ "$release" == "5" ]
then
  for f in $rootfs_path/etc/yum.repos.d/*.repo
  do
    sed -i 's/Source/SRPMS/g' $f
  done

  # make sure we only install rpm packages for the specified architecture.
  # see https://blog.nexcess.net/2012/07/19/64-bit-centos-installing-32-bit-packages/
  echo "multilib_policy=best" >> $rootfs_path/etc/yum.conf
fi

# install openssh-server
chroot $rootfs_path yum -y install openssh-server

# set a random root password. we are using the public key anyway
pwd=`< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c20`
echo $pwd | chroot $rootfs_path passwd root --stdin

install_public_keys $rootfs_path

configure_autostart $autostart $rootfs_path

info $cid $name $IPv4

