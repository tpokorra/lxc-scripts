#!/bin/bash

if [ -z $3 ]; then
  echo "call: $0 containername cid url"
  echo "eg: $0 mybuild03.lbs.solidcharity.com 3 www.example.org"
  exit
fi

HostIP=`ifconfig eth0 | grep "inet addr" | awk '{ print $2 }' | awk -F ':' '{ print $2 }'`
name=$1
cid=$2
url=$3
containerip=10.0.3.$cid

cat nginx.conf.tpl | \
  sed "s/HOSTIP/$HostIP/g" | \
  sed "s/HOSTPORT/80/g" | \
  sed "s/CONTAINERIP/$containerip/g" | \
  sed "s/CONTAINERURL/$url/g" | \
  sed "s/CONTAINERPORT/80/g" \
  > /etc/nginx/conf.d/$name.conf

mkdir -p /var/log/nginx/log
service nginx reload
