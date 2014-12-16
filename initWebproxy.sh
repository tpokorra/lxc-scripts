#!/bin/bash

if [ -z $2 ]; then
  echo "call: $0 cid url [subdir]"
  echo "eg: $0 3 www.example.org customer1"
  exit
fi

interface=eth0
# interface can be eth0, or p10p1, etc
interface=`cat /etc/network/interfaces | grep "auto" | grep -v "auto lo" | awk '{ print $2 }'`

HostIP=`ifconfig $interface | grep "inet addr" | awk '{ print $2 }' | awk -F ':' '{ print $2 }'`
cid=$1
url=$2
containerip=10.0.3.$cid

if [ -f /var/lib/certs/$url.crt ]; then
  port=443
else
  echo "cannot find ssl certificate at /var/lib/certs/$url.crt, therefore configuring http on port 80"
  port=80
fi

if [ -z $3 ]; then
  cidandsubid=$cid
  subdir=
else
  cidandsubid=$cid$3
  subdir="$3/"
fi

if [ $port -eq 80 ]; then 
  cat nginx.conf.tpl | \
    sed "s/HOSTIP/$HostIP/g" | \
    sed "s/HOSTPORT/80/g" | \
    sed "s/CONTAINERIP/$containerip/g" | \
    sed "s/CONTAINERID/$cid/g" | \
    sed "s/CONTAINERURL/$url/g" | \
    sed "s/CONTAINERPORT/80/g" \
    > /etc/nginx/conf.d/$cid-$url.conf
else
  cat nginx.sslconf.tpl | \
    sed "s/HOSTIP/$HostIP/g" | \
    sed "s/HOSTPORT/$port/g" | \
    sed "s/CONTAINERIP/$containerip/g" | \
    sed "s/CONTAINERIDSUBID/$cidandsubid/g" | \
    sed "s/CONTAINERID/$cid/g" | \
    sed "s/CONTAINERURL/$url/g" | \
    sed "s#SUBDIR#$subdir#g" | \
    sed "s/CONTAINERPORT/80/g" \
    > /etc/nginx/conf.d/$cid-$url.conf
fi
mkdir -p /var/log/nginx/log
service nginx reload
