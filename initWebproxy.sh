#!/bin/bash

if [ -z $2 ]; then
  echo "call: $0 cid url [subdir] [port]"
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
certurl=$url
wildcardurl="wildcard".$( cut -d '.' -f 2- <<< "$url" )
if [ -f /var/lib/certs/$url.crt ]; then
  generateCert=0
elif [ -f /var/lib/certs/$wildcardurl.crt ]; then
  generateCert=0
  certurl=$wildcardurl
else
  generateCert=1
fi

if [[ $NO_SSL == "yes" ]];
then
  generateCert=0
  port=80
fi

if [ -z $3 ]; then
  cidandsubid=$cid
  subdir=
else
  cidandsubid=$cid$3
  subdir="$3/"
fi

subport=80
if [ ! -z $4 ]; then
  cidandsubid=$cid$4
  subdir=
  subport=$4
fi

if [ $port -eq 80 ]; then 
  cat nginx.conf.tpl | \
    sed "s/HOSTIP/$HostIP/g" | \
    sed "s/HOSTPORT/80/g" | \
    sed "s/CONTAINERIP/$containerip/g" | \
    sed "s/CONTAINERID/$cid/g" | \
    sed "s/CONTAINERURL/$url/g" | \
    sed "s/CONTAINERPORT/$subport/g" \
    > /etc/nginx/conf.d/$cid-$url.conf
else
  cat nginx.sslconf.tpl | \
    sed "s/HOSTIP/$HostIP/g" | \
    sed "s/HOSTPORT/$port/g" | \
    sed "s/CONTAINERIP/$containerip/g" | \
    sed "s#CONTAINERIDSUBID#$cidandsubid#g" | \
    sed "s/CONTAINERID/$cid/g" | \
    sed "s/CONTAINERURL/$url/g" | \
    sed "s/CERTURL/$certurl/g" | \
    sed "s#SUBDIR#$subdir#g" | \
    sed "s#CONTAINERPORT#$subport#g" \
    > /etc/nginx/conf.d/$cid-$url.conf
fi
mkdir -p /var/log/nginx/log
if [ $generateCert -eq 1 ]
then
  ./letsencrypt.sh $cid-$url || exit -1
fi
systemctl reload nginx
