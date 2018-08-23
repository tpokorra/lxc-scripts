#!/bin/bash
if [ -z $2 ]; then
  echo "call: $0 cid port [hostport]"
  echo "eg: $0 3 80"
  echo "to drop a port use negative number: $0 3 -80"
  echo "to specify a port directly: $0 120 6667 6667"
  exit
fi

SCRIPTSPATH=`dirname ${BASH_SOURCE[0]}`
source $SCRIPTSPATH/lib.sh

interface=$(getOutwardInterface)
echo "outward interface:" $interface
HostIP=$(getIPOfInterface $interface)
echo "outward IP address:" $HostIP
interfaceBridge=$(getBridgeInterface)
echo "bridge interface:" $interfaceBridge
bridgeAddress=$(getIPOfInterface $interfaceBridge)
echo "bridge address:" $bridgeAddress

cid=$1
guestip=${bridgeAddress:0: -2}.$cid
echo "guestip: "$guestip
port=$2
remove=0

# remove existing routes
if [ $port -lt 0 ]
then
  port=$((-1 * $port))
  remove=1 
fi

if [ -z $3 ]
then
  firstdigit=${port:0:1}
  hostport=$(($firstdigit * 1000 + $cid))
else
  hostport=$3
fi

# Ubuntu
rules=/etc/iptables.rules
if [ ! -f $rules ]
then
  # Fedora
  rules=/etc/sysconfig/iptables
fi

# first save the iptables
if [ -f /etc/network/if-post-down.d/iptablessave ]
then
  /etc/network/if-post-down.d/iptablessave
else
  iptables-save > $rules
fi

if [ $remove -eq 1 ]
then
  if [ ! -z "`cat $rules | grep "to-destination ${guestip}:${port}"`" ]
  then
    iptables -t nat -D PREROUTING -p tcp -d ${HostIP} --dport $hostport -i ${interface} -j DNAT --to-destination ${guestip}:$port
    echo "dropping rule ${HostIP}:$hostport => ${guestip}:${port}"
  fi
else
  if [ ! -z "`cat $rules | grep "PREROUTING" | grep "dport $hostport "`" ]
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
  systemctl status firewalld > /dev/null
  if [ $? -eq 0 ]
  then
    # firewalld is running
    firewall-cmd --runtime-to-permanent
  fi
fi
