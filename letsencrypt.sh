#!/bin/bash

if [ ! -d ~/letsencrypt ]
then
  mkdir ~/letsencrypt
fi

if [ ! -f ~/letsencrypt/acme_tiny.py ]
then
  wget https://raw.githubusercontent.com/diafygi/acme-tiny/master/acme_tiny.py -O ~/letsencrypt/acme_tiny.py
fi

if [ ! -f ~/letsencrypt/account.key ]
then
  openssl genrsa 4096 > ~/letsencrypt/account.key
fi

if [ ! -f ~/letsencrypt/lets-encrypt-x3-cross-signed.pem ]
then
  wget https://letsencrypt.org/certs/lets-encrypt-x3-cross-signed.pem -O ~/letsencrypt/lets-encrypt-x3-cross-signed.pem
fi

if [ -z $1 ]
then
  echo "specify which domain should get a new lets encrypt certificate, or all"
  echo "$0 33-mydomain.com"
  echo "$0 all"
  exit -1
fi
domain=$1

function new_letsencrypt_certificate {
domainconf=$1
domain=`basename $domainconf`
domain=${domain:0:-5}
posdash=`expr index "$domain" "-"`
cid=${domain:0:posdash-1}
domain=${domain:posdash}
challengedir=/tmp/$cid/challenge/.well-known/acme-challenge/
  echo "new certificate for $domain"

  cd ~/letsencrypt
  openssl genrsa 4096 > $domain.key
  openssl req -new -sha256 -key $domain.key -subj "/CN=$domain" > $domain.csr
  sed -i "s~return 302~#return 302~g" $domainconf
  sed -i "s~#location / { root /tmp/.*}~location / { root /tmp/$cid/challenge; }~g" $domainconf
  mkdir -p $challengedir
  service nginx reload
  error=0
  python acme_tiny.py --account-key ./account.key --csr ./$domain.csr --acme-dir $challengedir > ./$domain.crt || error=1
  rm -Rf /tmp/$cid

  sed -i "s~#return 302~return 302~g" $domainconf
  sed -i "s~location / { root /tmp/~#location / { root /tmp/~g" $domainconf

  if [ $error -ne 1 ]
  then
    cp -f $domain.key /var/lib/certs/$domain.key
    cat $domain.crt lets-encrypt-x3-cross-signed.pem > /var/lib/certs/$domain.crt
  fi

  service nginx reload
  cd -
}

if [ "$domain" == "all" ]
then
  for f in /etc/nginx/conf.d/*
  do
    if [ "`cat $f | grep challenge`" != "" ]
    then
      new_letsencrypt_certificate $f
    fi
  done
else
  new_letsencrypt_certificate /etc/nginx/conf.d/$domain.conf
fi
