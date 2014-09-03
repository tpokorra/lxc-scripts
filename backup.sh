#!/bin/bash

if [ -z $2 ]; then
  echo "call: $0 backuphost username"
  echo "eg: $0 mybackup.com myusername"
  exit
fi

backuphost=$1
username=$2
thishost=`hostname`

for d in /var/lib/lxc/*
do
  putcmd="$putcmd 
put ${d}/config lxc/`basename $d`.config"
done

echo "put /etc/iptables.rules
put /etc/nginx/conf.d/* nginx
put /var/lib/certs/* certs
$putcmd
"  | sftp $username@$backuphost:$thishost || echo "problem, did not backup everything!!!"

