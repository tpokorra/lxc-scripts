#!/bin/bash
if [ -z $1 ]; then
  echo "call: $0 containername cid"
  echo "eg: $0 mybuild03.lbs.solidcharity.com 3"
  exit
fi

HostIP=`ifconfig eth0 | grep "inet addr" | awk '{ print $2 }' | awk -F ':' '{ print $2 }'`
if [ "$1" == "" ]; then exit; fi
name=$1
guestip=`awk '{ print $4,$3 }' /var/lib/misc/dnsmasq.leases | column -t | grep "$name" | awk '{ print $2 }'`
if [ ! -z "$guestip" ]; then
  cid=`echo "$guestip" | awk -F '.' '{ print $4 }'`
else
  cid=$2
  guestip=10.0.3.$cid
fi
if [ -z "$cid" ]; then
  echo "you need to provide a cid number"
  exit 1
fi


iptables -t nat -A PREROUTING -p tcp -d ${HostIP} --dport $((2000 + $cid)) -i eth0 -j DNAT --to-destination ${guestip}:22
iptables -t nat -A PREROUTING -p tcp -d ${HostIP} --dport $((8000 + $cid)) -i eth0 -j DNAT --to-destination ${guestip}:80
iptables -t nat -A PREROUTING -p tcp -d ${HostIP} --dport $((4000 + $cid)) -i eth0 -j DNAT --to-destination ${guestip}:443
echo "forwarding ${HostIP}:$((2000 + $cid)) => ${guestip}:22"
echo "forwarding ${HostIP}:$((4000 + $cid)) => ${guestip}:443"
echo "forwarding ${HostIP}:$((8000 + $cid)) => ${guestip}:80"
