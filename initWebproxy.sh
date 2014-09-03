#!/bin/bash

if [ -z $3 ]; then
  echo "call: $0 containername cid url [subdir]"
  echo "eg: $0 mybuild03.lbs.solidcharity.com 3 www.example.org customer1"
  exit
fi

HostIP=`ifconfig eth0 | grep "inet addr" | awk '{ print $2 }' | awk -F ':' '{ print $2 }'`
name=$1
cid=$2
url=$3
containerip=10.0.3.$cid

if [ -f /var/lib/certs/$url.crt ]; then
  port=443
else
  echo "cannot find ssl certificate at /var/lib/certs/$url.crt, therefore configuring http on port 80"
  port=80
fi

if [ -z $4 ]; then
  cidandsubid=$cid
  subdir=
else
  cidandsubid=$cid$4
  subdir="$4/"
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
