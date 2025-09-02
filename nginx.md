$ sudo dnf install -y nginx   
$ sudo systemctl enable nginx  
$ sudo systemctl start nginx  
$ sudo systemctl status nginx  

# Скопировать сертификаты   

$ cp /install/ssh/mysite.crt /etc/nginx/certs/mysite.crt  
$ cp /install/ssh/mysite.key /etc/nginx/certs/mysite.key  
$ sudo chown -R root:root /etc/nginx  

$ sudo nano /etc/nginx/nginx.conf  
или
# Вставляем в файлик если для геосервера  
$ sudo nano /etc/nginx/conf.d/mysite.conf  

```

map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 80;
    access_log off;
    server_name mysite;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_namemysite;

    ssl_protocols               TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_session_cache           shared:SSL:20m;
    ssl_session_timeout         15m;
    ssl_prefer_server_ciphers   on;

    ssl_stapling on;
    ssl_certificate /etc/nginx/certs/mysite.crt; # Укажите путь до сертификатов
    ssl_certificate_key /etc/nginx/certs/mysite.key;  # Укажите путь до сертификатов

    access_log /var/log/nginx/geosrv.access.log;
    error_log /var/log/nginx/geosrv.error.log;

    location / {
        proxy_pass http://mysite:8080;
        proxy_ssl_server_name  on; #mandatory
        proxy_set_header Host  mysite;
        proxy_ssl_name mysite;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Host $host;
        proxy_set_header X-Forwarded-Server $host;
        proxy_set_header X-Forwarded-Port $server_port;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_redirect http://$host/ https://$host/;
        proxy_cookie_path /geoserver /;
        proxy_cookie_flags ~ secure samesite=none;
    }
}


```


$ sudo systemctl restart nginx  
$ sudo systemctl status nginx  
$ sudo journalctl -xeu nginx.service  
