#!/bin/bash
if [ -z $2 ]; then
  echo "call: $0 cid port"
  echo "eg: $0 3 80"
  echo "to drop a port use negative number: $0 3 -80"
  exit
fi

interface=$(getOutwardInterface)
HostIP=$(getIPOfInterface $interface)
interfaceBridge=$(getBridgeInterface)
bridgeAddress=$(getIPOfInterface $interfaceBridge)

cid=$1
guestip=${bridgeAddress:0: -2}.$cid
port=$2
remove=0

# remove existing routes
if [ $port -lt 0 ]
then
  port=$((-1 * $port))
  remove=1 
fi

firstdigit=${port:0:1}
hostport=$(($firstdigit * 1000 + $cid))

# Ubuntu
rules=/etc/iptables.rules
if [ ! -f $rules ]
then
  # Fedora
  rules=/etc/sysconfig/iptables
fi

if [ $remove -eq 1 ]
then
  if [ ! -z "`cat $rules | grep "to-destination ${guestip}:${port}"`" ]
  then
    iptables -t nat -D PREROUTING -p tcp -d ${HostIP} --dport $hostport -i ${interface} -j DNAT --to-destination ${guestip}:$port
    echo "dropping rule ${HostIP}:$hostport => ${guestip}:${port}"
  fi
else
  if [ ! -z "`cat $rules | grep "dport $hostport "`" ]
  then
    echo "there is already a mapping for port " $hostport
  else
    iptables -t nat -A PREROUTING -p tcp -d ${HostIP} --dport $hostport -i ${interface} -j DNAT --to-destination ${guestip}:$port
    echo "forwarding ${HostIP}:$hostport => ${guestip}:${port}"
  fi
fi

if [ -f /etc/network/if-post-down.d/iptablessave ]
then
  /etc/network/if-post-down.d/iptablessave
else
  iptables-save > $rules
fi

