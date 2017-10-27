#!/bin/bash

if [ -z $2 ]; then
  echo "call: $0 cid url [subdir]"
  echo "eg: $0 3 www.example.org customer1"
  exit
fi

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

interface=$(getOutwardInterface)
HostIP=$(getIPOfInterface $interface)
interfaceBridge=$(getBridgeInterface)
bridgeAddress=$(getIPOfInterface $interfaceBridge)

cid=$1
containerip=${bridgeAddress:0: -2}.$cid

url=$2

port=443
if [ -f /var/lib/certs/$url.crt ]; then
  generateCert=0
else
  touch /var/lib/certs/$url.crt
  touch /var/lib/certs/$url.key
  generateCert=1
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
    sed "s#CONTAINERIDSUBID#$cidandsubid#g" | \
    sed "s/CONTAINERID/$cid/g" | \
    sed "s/CONTAINERURL/$url/g" | \
    sed "s#SUBDIR#$subdir#g" | \
    sed "s/CONTAINERPORT/80/g" \
    > /etc/nginx/conf.d/$cid-$url.conf
fi
if [ $generateCert -eq 1 ]
then
  # disable ssl for the moment, the certificate is not valid yet
  sed -i "s/ssl/#ssl/g" /etc/nginx/conf.d/$cid-$url.conf
fi
mkdir -p /var/log/nginx/log
service nginx reload

if [ $generateCert -eq 1 ]
then
  ./letsencrypt.sh $cid-$url || exit -1
  sed -i "s/#ssl/ssl/g" /etc/nginx/conf.d/$cid-$url.conf
  service nginx reload
fi
