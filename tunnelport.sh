#!/bin/bash
if [ -z $3 ]; then
  echo "call: $0 containername cid port"
  echo "eg: $0 mybuild03.lbs.solidcharity.com 3 80"
  echo "to drop a port use negative number: $0 mybuild03.lbs.solidcharity.com 3 -80"
  exit
fi

HostIP=`ifconfig eth0 | grep "inet addr" | awk '{ print $2 }' | awk -F ':' '{ print $2 }'`
name=$1
cid=$2
guestip=10.0.3.$cid
port=$3
remove=0

# remove existing routes
if [ $port -lt 0 ]
then
  port=$((-1 * $port))
  remove=1 
fi

firstdigit=${port:0:1}
hostport=$(($firstdigit * 1000 + $cid))
if [ $remove -eq 1 ]
then
  if [ ! -z "`cat /etc/iptables.rules | grep "to-destination ${guestip}:${port}"`" ]
  then
    iptables -t nat -D PREROUTING -p tcp -d ${HostIP} --dport $hostport -i eth0 -j DNAT --to-destination ${guestip}:$port
    echo "dropping rule ${HostIP}:$hostport => ${guestip}:${port}"
  fi
else
  if [ ! -z "`cat /etc/iptables.rules | grep "dport $hostport "`" ]
  then
    echo "there is already a mapping for port " $hostport
  else
    iptables -t nat -A PREROUTING -p tcp -d ${HostIP} --dport $hostport -i eth0 -j DNAT --to-destination ${guestip}:$port
    echo "forwarding ${HostIP}:$hostport => ${guestip}:${port}"
  fi
fi

/etc/network/if-post-down.d/iptablessave
