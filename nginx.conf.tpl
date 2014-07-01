## Start CONTAINERURL ##
upstream containerCONTAINERID  {
      server CONTAINERIP:CONTAINERPORT;
}

server {
    listen       HOSTIP:HOSTPORT;
    server_name  CONTAINERURL;
 
    access_log  /var/log/nginx/log/CONTAINERURL.access.log;
    error_log  /var/log/nginx/log/CONTAINERURL.error.log;
    root   /usr/share/nginx/html;
    index  index.html index.htm;
 
    ## send request back to lbs ##
    location / {
     proxy_pass  http://containerCONTAINERID;
     proxy_next_upstream error timeout invalid_header http_500 http_502 http_503 http_504;
     proxy_redirect off;
     proxy_buffering off;
     proxy_set_header        Host            $host;
     proxy_set_header        X-Real-IP       $remote_addr;
     proxy_set_header        X-Forwarded-For $proxy_add_x_forwarded_for;
   }
}
## End CONTAINERURL ##
