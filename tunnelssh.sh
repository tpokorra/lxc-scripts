#!/bin/bash
if [ -z $2 ]; then
  echo "call: $0 containername cid"
  echo "eg: $0 mybuild03.lbs.solidcharity.com 3"
  exit
fi

HostIP=`ifconfig eth0 | grep "inet addr" | awk '{ print $2 }' | awk -F ':' '{ print $2 }'`
name=$1
cid=$2
guestip=10.0.3.$cid

# remove existing routes
iptables -t nat -D PREROUTING -p tcp -d ${HostIP} --dport $((2000 + $cid)) -i eth0 -j DNAT --to-destination ${guestip}:22
iptables -t nat -D PREROUTING -p tcp -d ${HostIP} --dport $((8000 + $cid)) -i eth0 -j DNAT --to-destination ${guestip}:80
iptables -t nat -D PREROUTING -p tcp -d ${HostIP} --dport $((4000 + $cid)) -i eth0 -j DNAT --to-destination ${guestip}:443

iptables -t nat -A PREROUTING -p tcp -d ${HostIP} --dport $((2000 + $cid)) -i eth0 -j DNAT --to-destination ${guestip}:22
echo "forwarding ${HostIP}:$((2000 + $cid)) => ${guestip}:22"
#iptables -t nat -A PREROUTING -p tcp -d ${HostIP} --dport $((8000 + $cid)) -i eth0 -j DNAT --to-destination ${guestip}:80
#echo "forwarding ${HostIP}:$((8000 + $cid)) => ${guestip}:80"
#iptables -t nat -A PREROUTING -p tcp -d ${HostIP} --dport $((4000 + $cid)) -i eth0 -j DNAT --to-destination ${guestip}:443
#echo "forwarding ${HostIP}:$((4000 + $cid)) => ${guestip}:443"

/etc/network/if-post-down.d/iptablessave
