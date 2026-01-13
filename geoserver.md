$ dnf check-update  
$ sudo dnf update & sudo dnf  upgrade --skip-broken  
  
$ sudo systemctl status iptables.service   
$ sudo systemctl stop iptables.service  
$ sudo dnf remove iptables.service  
  
$ sudo cat /etc/passwd | grep my-user  
$ sudo useradd my-user  
$ sudo passwd my-user  
  
Password: my-user123  
  
$ mkdir /install  
$ sudo chmod 777 /install  
$ cd /install  
  
# Установка Java  
  
скопировать jdk-17.0.8_linux-x64_bin.rpm в ~/install  
или wget [https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.rpm](https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.rpm)  
$ sudo rpm -i jdk-17.0.8_linux-x64_bin.rpm  
$ java -version  
$ sudo alternatives --config java  
  
Далее исправляем файлик **/etc/profile**  
$ sudo nano **/etc/profile**  
и вставляем:  
  
```
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-21.0.7.0.6-1.el7.x86_64/
export JRE_HOME=/usr/lib/jvm/java-21-openjdk-21.0.7.0.6-1.el7.x86_64/
export PATH=$PATH:/usr/lib/jvm/java-21-openjdk-21.0.7.0.6-1.el7.x86_64/bin
```


$ sudo reboot now
  
$ ls -la ${JAVA_HOME}  
  
Скопировать [geoserver-2.23.2-bin.zip](http://sourceforge.net/projects/geoserver/files/GeoServer/2.23.2/geoserver-2.23.2-bin.zip) в /tmp  
  
wget [http://sourceforge.net/projects/geoserver/files/GeoServer/2.23.2/geoserver-2.23.2-bin.zip](http://sourceforge.net/projects/geoserver/files/GeoServer/2.23.2/geoserver-2.23.2-bin.zip)  
  
$ sudo mkdir /opt/geoserver  
$ sudo unzip -d /opt/geoserver geoserver-xxx-bin.zip  
  
$ sudo chown -R my-user:my-user /opt/geoserver  
$ ll /opt/geoserver/data_dir/gwc  
$ sudo chmod 777 -R /opt/geoserver/data_dir/gwc  
  
$  ls -la /opt/geoserver/bin/startup.sh  
$  ls -la /opt/geoserver/bin/shutdown.sh  
$ sudo chmod 777 /opt/geoserver/bin/shutdown.sh  
$ sudo chmod 777 /opt/geoserver/bin/startup.sh  
  
$ sudo nano /etc/systemd/system/geoserver.service  
$ more /etc/systemd/system/geoserver.service  
   
 Содержимое: /etc/systemd/system/geoserver.service  
  
```
[Unit]
Description=GeoServer Service
After=network.target

[Service]
Type=simple
User=my-user
Group=my-user
Environment="GEOSERVER_HOME=/opt/geoserver"
Environment="GEOSERVER_DATA_DIR=/data2/geoserver/data_dir"
Environment="GEOWEBCACHE_CACHE_DIR=/data2/geoserver/gwc"
ExecStart=/opt/geoserver/bin/startup.sh
ExecStop=/opt/geoserver/bin/shutdown.sh

[Install]
WantedBy=multi-user.target
```


$ sudo systemctl daemon-reload    
$ sudo systemctl enable --now geoserver.service    
$ sudo systemctl status geoserver.service  
$ sudo journalctl -xeu geoserver.service
  
● geoserver.service  
  
     Loaded: loaded (/usr/lib/systemd/system/geoserver.service; enabled; vendor preset: disabled)  
     Active: **active (running)** since Tue 2023-08-15 10:24:39 +05; 14s ago  
   Main PID: 3499 (java)  
      Tasks: 46 (limit: 9498)  
     Memory: 401.1M  
        CPU: 22.288s  
     CGroup: /system.slice/geoserver.service  
  
             └─3499 java -DNoJavaOpts -Xbootclasspath/a:/opt/geoserver/webapps/geoserver/WEB-INF/lib/marlin-0.9.3.jar -Dsun.java2d.renderer=org.marlin.pisces.MarlinRenderingEngine -Djetty.base=/opt/geoserver -DGEOSERVER_DATA_DIR=/opt/geoserver/data_dir -Djava.awt.headless=tru  
  
$  netstat -antu| grep 8080  
$ lsof  | grep java  
$ sudo dnf install w3m w3m-img   
  
  
$ cd    
$ rm -rf /tmp/geoserver    
$  
  
1. In the GeoServer bin directory, locate the `start.ini` file, open it, and change the property `jetty.http.port` to `8083`, so as not to conflict with other applications that might be running on 8080. The rest of this training assumes GeoServer is running on port `8083`.  
2. If you are using Java 17 or later, move into `webapss/geoserver/WEB-INF/lib` and remove the file named `marlin-<version>.jar` (e.g. `marlin-0.9.3.jar`).  
  
```clike
sudo rm /opt/geoserver/webapps/geoserver/WEB-INF/lib/marlin-0.9.3.jar
```

Настройка CORS для GeoServer  
  
$ sudo nano /opt/geoserver/webapps/geoserver/WEB-INF/web.xml  
  

```
<!-- Uncomment following filter to enable CORS in Jetty. Do not forget the second config block further down.
    <filter>
      <filter-name>cross-origin</filter-name>
      <filter-class>org.eclipse.jetty.servlets.CrossOriginFilter</filter-class>
      <init-param>
        <param-name>chainPreflight</param-name>
        <param-value>false</param-value>
      </init-param>
      <init-param>
        <param-name>allowedOrigins</param-name>
        <param-value>*</param-value>
      </init-param>
      <init-param>
        <param-name>allowedMethods</param-name>
        <param-value>GET,POST,PUT,DELETE,HEAD,OPTIONS</param-value>
      </init-param>
      <init-param>
        <param-name>allowedHeaders</param-name>
        <param-value>*</param-value>
      </init-param>
    </filter>
    -->

<!-- Uncomment following filter to enable CORS
    <filter-mapping>
        <filter-name>cross-origin</filter-name>
        <url-pattern>/*</url-pattern>
    </filter-mapping>
    -->
```


[http://myserver:8080](http://myserver:8080/)
  
[http://myserver:8080](http://myserver:8080/)[/geoserver/web](http://myserver:8080/geoserver/web)  
  
Для доступа используются login|password по умолчанию (**admin|geoserver**)  
  
Изменяем мастер-пароль по-дефолту на **geoserver2**  
Изменяем админ-пароль по-дефолту на **geoserver2**  
  
# Настройка геосетки для работы с Кэшсервисом
  
1. Перейдите по пути [http://myserver:8080/geoserver/web](http://myserver:8080/geoserver/web) и авторизуйтесь в панели администратора  
2. Перейдите в пункт «**Настройки GeoWebCache**»  
3. В выпадающем списке «**Добавить геосетку по умолчанию**» выбрать пункт «**WebMercatorQuad**» и нажать пиктограмму «**+**»  
4. Убедится, что геосетка добавленная в таблицу  
5. Сохранить изменения используя кнопки «Применить» или «Сохранить»  
  
# Перенос data_dir в отдельную директорию /data2   
  
$ sudo chown -R my-user:my-user /data2  
$ sudo mkdir /data2/geoserver  
$ sudo mv -f /opt/geoserver/data_dir/ /data2/geoserver/    
$ sudo chown -R my-user:my-user /data2  
$ cd /opt/geoserver/  
$ sudo ln -s /data2/geoserver/data_dir/ /opt/geoserver/data_dir  
  
  
$GEOSERVER_DATA_DIR  
  
$ sudo nano /etc/profile  
$ export GEOSERVER_DATA_DIR=/data2/geoserver/data_dir  
$ sudo reboot now  
$ echo $GEOSERVER_DATA_DIR  
$ sudo nano /opt/geoserver/webapps/geoserver/WEB-INF/web.xml  
  
Раскомментировать и поправить  
  
<!--  
  
    <context-param>  
  
       <param-name>GEOSERVER_DATA_DIR</param-name>  
  
        <param-value>C:\eclipse\workspace\geoserver_trunk\cite\confCiteWFSPostGIS</param-value>  
  
    </context-param>  
  
   -->  
  
Поправить вот так:  
  
<context-param>  
  <param-name>GEOSERVER_DATA_DIR</param-name>  
  <param-value>$GEOSERVER_DATA_DIR</param-value>
</context-param>  
  
$  
  
## **Изменение пути к кэшу GWC**
  
$ cd /data1  
$ sudo mkdir -p /data1/geoserver/gwc  
$ sudo chown -R my-user:my-user /data  
$ sudo nano /etc/profile  
$ export GEOWEBCACHE_CACHE_DIR=/data/geoserver/gwc  
  
$ sudo nano /opt/geoserver/webapps/geoserver/WEB-INF/web.xml  
  
Редактируем файл ./geoserver/webapps/geoserver/WEB-INF/web.xml:  
  
```php
...
<context-param>
   <param-name>GEOWEBCACHE_CACHE_DIR</param-name>
   <param-value>$GEOWEBCACHE_CACHE_DIR</param-value>
</context-param>
```


$ sudo reboot now  
  
$ echo $GEOWEBCACHE_CACHE_DIR  
  
# Установка шрифтов 
  
1. Копируем шрифты в /usr/share/fonts/[своя папка]  
2. Обновляем кэш шрифтов: sudo fc-cache -f -v  
3. Перезагружаем Geoserver  
4. sudo systemctl restart geoserver.service  
5. sudo systemctl status --now geoserver.service  
  
[http://myserver:8080/geoserver/web/](http://myserver:8080/geoserver/web/?1)  
  
login:  
  
# Настройка прокси через nginx [  
  
Редактируем файл ./geoserver/webapps/geoserver/WEB-INF/web.xml:  
  
$ sudo nano /opt/geoserver/webapps/geoserver/WEB-INF/web.xml  
  
Добавьте этот параметр ниже <context-param>  

```
<context-param>
        <param-name>PROXY_BASE_URL</param-name>
    <param-value>https://myserver/geoserver</param-value>
</context-param>

<context-param>
        <param-name>GEOSERVER_CSRF_WHITELIST</param-name>
        <param-value>myserver</param-value>
</context-param>
```

Перезагружаем Geoserver  
3. sudo systemctl restart geoserver.service  
4. sudo systemctl status --now geoserver.service  
  
  
  
### Отключаем SE linux  
  
$ sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config    
$ sudo setenforce 0  
  
Скопируйте и сертификаты nginx.zip в /install  
  
$ cd /install  
$ sudo unzip nginx.zip  
$ sudo rpm -i nginx/* или sudo dnf install nginx  
$ sudo systemctl enable nginx  
$ sudo systemctl cat nginx.service  
$ sudo systemctl start nginx  
$ sudo systemctl status nginx  
$ sudo ls -la /etc/nginx/certs  
$ sudo mkdir /etc/nginx/certs  
$ sudo chown root:root -R /etc/nginx/certs  
$ sudo cp <prerequire_path>/(Ваши сертификаты) /etc/nginx/certs  
  
$ sudo nano /etc/nginx/conf.d/geoserver.conf  
  
# Вставляем в файлик/etc/nginx/conf.d/geoserver.conf  
  
```

map $http_upgrade $connection_upgrade {
    default upgrade;
    '' close;
}

server {
    listen 80;
    access_log off;
    server_name myserver;
    return 301 https://$server_name$request_uri;
}

server {
    listen 443 ssl;
    server_name myserver;

    ssl_protocols               TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
    ssl_session_cache           shared:SSL:20m;
    ssl_session_timeout         15m;
    ssl_prefer_server_ciphers   on;

    ssl_stapling on;
    ssl_certificate /etc/nginx/certs/myserver.crt; # Укажите путь до сертификатов
    ssl_certificate_key /etc/nginx/certs/myserver.key;  # Укажите путь до сертификатов

    access_log /var/log/nginx/geosrv.access.log;
    error_log /var/log/nginx/geosrv.error.log;

    location / {
        proxy_pass http://myserver:8080;
        proxy_ssl_server_name  on; #mandatory
        proxy_set_header Host  myserver;
        proxy_ssl_name myserver;
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
$  
  
[https://myserver/geoserver/](https://myserver/geoserver/web/?0)  
  
login: admin  
password: geoserver      


# Настройка геосетки для работы с Кэшсервисом 

1. Перейдите по пути [https://myserver/geoserver/](https://myserver/geoserver/web/?0)   и авторизуйтесь в панели администратора
2. Перейдите в пункт «**Настройки GeoWebCache**»
3. В выпадающем списке «**Добавить геосетку по умолчанию**» выбрать пункт «**WebMercatorQuad**» и нажать пиктограмму «**+**»
4. Убедится, что геосетка добавленная в таблицу
5. Сохранить изменения используя кнопки «Применить» или «Сохранить»


# Перенос data_dir в отдельную директорию /data2 

### Вариант 1
$ sudo systemctl stop geoserver.service
$ sudo chown -R my-user:my-user /data2
$ sudo mkdir /data2/geoserver
$ sudo mv -f /opt/geoserver/data_dir/ /data2/geoserver/  
$ sudo chown -R my-user:my-user /data2
$ cd /opt/geoserver/
$ sudo ln -s /data2/geoserver/data_dir/ /opt/geoserver/data_dir


$GEOSERVER_DATA_DIR

$ sudo nano /etc/profile
$ export GEOSERVER_DATA_DIR=/data2/geoserver/data_dir
$ sudo reboot now
$ echo $GEOSERVER_DATA_DIR
$ sudo nano /opt/geoserver/webapps/geoserver/WEB-INF/web.xml

Раскомментировать и поправить
```
<!--
    <context-param>
       <param-name>GEOSERVER_DATA_DIR</param-name>
        <param-value>C:\eclipse\workspace\geoserver_trunk\cite\confCiteWFSPostGIS</param-value>
    </context-param>
   -->
```

Поправить вот так:
```
<context-param>
  <param-name>GEOSERVER_DATA_DIR</param-name>
  <param-value>$GEOSERVER_DATA_DIR</param-value>
</context-param>
```


### Вариант 2 

$ sudo systemctl stop geoserver.service
**Создаем директорию**
$ sudo mkdir /data1/data_dir

**Переносим данные из data_dir геосервера в созданную директорию**
$ sudo cp -r /opt/geoserver/data_dir/* /data1/data_dir/

$ $ sudo chown -R my-user:my-user /data2 

**Переназначаем директорию для геосервера**
$ sudo nano /opt/geoserver/bin/startup.sh

**в блоке** **#Find the configuration directory: GEOSERVER_DATA_DIR**
**меняем путь до data_dir**

**Вместо**
```
if [ -z "${GEOSERVER_DATA_DIR:-}" ]; then
    if [ -r "${GEOSERVER_HOME}/data_dir" ]; then
        export GEOSERVER_DATA_DIR="${GEOSERVER_HOME}/data_dir"
    else
        echo "No GEOSERVER_DATA_DIR found, using application defaults"
              GEOSERVER_DATA_DIR=""
    fi
fi
```


**Ставим**
```
if [ -z "${GEOSERVER_DATA_DIR:-}" ]; then
    if [ -r "/data1/data_dir" ]; then
        export GEOSERVER_DATA_DIR="/data1/data_dir"
    else
        echo "No GEOSERVER_DATA_DIR found, using application defaults"
              GEOSERVER_DATA_DIR=""
    fi
fi
```

$ sudo nano /opt/geoserver/webapps/geoserver/WEB-INF/web.xml

Раскомментировать и поправить
```
<!--
    <context-param>
       <param-name>GEOSERVER_DATA_DIR</param-name>
        <param-value>C:\eclipse\workspace\geoserver_trunk\cite\confCiteWFSPostGIS</param-value>
    </context-param>
   -->
```

Поправить вот так:
```
<context-param>
  <param-name>GEOSERVER_DATA_DIR</param-name>
  <param-value>$GEOSERVER_DATA_DIR</param-value>
</context-param>
```



**Перезапускаем геосервер**

$ sudo systemctl restart geoserver

**переходим в ui во вкладку "состояние сервера"**
в поле "каталог данных", должна быть директория, которую создавали


## **Изменение пути к кэшу GWC**

$ cd /data1
$ sudo mkdir -p /data1/geoserver/gwc
$ sudo chown -R my-user:my-user /data1
$ sudo nano /etc/profile
$ export GEOWEBCACHE_CACHE_DIR=/data1/geoserver/gwc

$ sudo nano /opt/geoserver/webapps/geoserver/WEB-INF/web.xml

Редактируем файл ./geoserver/webapps/geoserver/WEB-INF/web.xml:

```xml
...
<context-param>
   <param-name>GEOWEBCACHE_CACHE_DIR</param-name>
   <param-value>$GEOWEBCACHE_CACHE_DIR</param-value>
</context-param>
```


$ sudo reboot now

$ echo $GEOWEBCACHE_CACHE_DIR

### Настройка blob-хранилищ для встроенного GeoWebCache 

Геосервер-Blob-хранилище
"**Добавить новое**"
указываем: 
Тип: "**MBTiles BlobStore**"
Root Directory : **/data1/geoserver/mbtiles или /data1/geoserver/gwc**
MBTiles Metadata Directory: **/data1/geoserver/mbtiles**



login:

# Настройка прокси через nginx 

Редактируем файл ./geoserver/webapps/geoserver/WEB-INF/web.xml:

$ sudo nano /opt/geoserver/webapps/geoserver/WEB-INF/web.xml

Добавьте этот параметр ниже <context-param>

```
<context-param>
        <param-name>PROXY_BASE_URL</param-name>
    <param-value>https://tmn-nst-test-geosrv.tm.novatek.int/geoserver</param-value>
</context-param>

<context-param>
        <param-name>GEOSERVER_CSRF_WHITELIST</param-name>
        <param-value>tmn-nst-test-geosrv.tm.novatek.int</param-value>
</context-param>
```

Перезагружаем Geoserver
3. sudo systemctl restart geoserver.service
4. sudo systemctl status --now geoserver.service


