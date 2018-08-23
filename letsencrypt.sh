#!/bin/bash

max_certificates_per_run=5

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

function need_new_certificate {
domainconf=$1
domain=`basename $domainconf`
domain=${domain:0:-5}
posdash=`expr index "$domain" "-"`
cid=${domain:0:posdash-1}
domain=${domain:posdash}
need_new=0

crtfile=/var/lib/certs/$domain.crt

if [ ! -f $crtfile ]
then
  return
fi

enddate=`openssl x509 -enddate -noout -in $crtfile | cut -d= -f2-`
# show date in readable format, eg. 2016-07-03
#date -d "$enddate" '+%F'
# convert to timestamp for comparison
enddate=`date -d "$enddate" '+%s'`
threeweeksfromnow=`date -d "+21 days" '+%s'`
echo "certificate valid till " `date +%Y-%m-%d -d @$enddate` $domain
if [ $enddate -lt $threeweeksfromnow ]
then
  need_new=1
fi
}

declare -A domain_counter
function new_letsencrypt_certificate {
domainconf=$1
domain=`basename $domainconf`
domain=${domain:0:-5}
posdash=`expr index "$domain" "-"`
cid=${domain:0:posdash-1}
domain=${domain:posdash}
challengedir=/var/lib/certs/tmp/$cid/challenge/.well-known/acme-challenge/

  # TODO this does not support toplevel domains like .co.uk, etc
  maindomain=`echo $domain | awk -F. '{print $(NF-1) "." $NF}'`
  maindomain=${maindomain/./_}
  counter=${domain_counter[$maindomain]}
  domain_counter[$maindomain]=$((${domain_counter[$maindomain]}+1))
  if [ ${domain_counter[$maindomain]} -gt $max_certificates_per_run ]
  then
    # To avoid hitting the limit of new certificates within a week per domain, we delay the certificate for the next run
    echo "delaying new certificate for $domain"
    return
  fi

  echo "new certificate for $domain"

  cd ~/letsencrypt
  openssl genrsa 4096 > $domain.key
  openssl req -new -sha256 -key $domain.key -subj "/CN=$domain" > $domain.csr
  sed -i "s~#location / { root .*/tmp/.*}~location / { root /var/lib/certs/tmp/$cid/challenge; }~g" $domainconf
  cat $domainconf | grep "location /.well-known" || sed -i "s~location / ~location /.well-known/acme-challenge/ { root /var/lib/certs/tmp/$cid/challenge; }\n    location / ~g" $domainconf
  mkdir -p $challengedir
  systemctl reload nginx || exit -1
  error=0
  python acme_tiny.py --account-key ./account.key --csr ./$domain.csr --acme-dir $challengedir > ./$domain.crt || error=1
  rm -Rf /var/lib/certs/tmp/$cid

  sed -i "s~location /.well-known/acme-challenge/ { root /var/lib/certs/tmp/~#location /.well-known/acme-challenge/ { root /var/lib/certs/tmp/~g" $domainconf

  if [ $error -ne 1 ]
  then
    cp -f $domain.key /var/lib/certs/$domain.key
    cat $domain.crt lets-encrypt-x3-cross-signed.pem > /var/lib/certs/$domain.crt
  fi

  systemctl reload nginx || exit -1
  cd -

  if [ $error -eq 1 ]
  then
    exit -1
  fi
}

if [ "$domain" == "all" ]
then
  for f in /etc/nginx/conf.d/*
  do
    if [ "`cat $f | grep challenge`" != "" ]
    then
      need_new_certificate $f
      if [ $need_new -eq 1 ]
      then
        new_letsencrypt_certificate $f
      fi
    fi
  done
else
  new_letsencrypt_certificate /etc/nginx/conf.d/$domain.conf
fi
