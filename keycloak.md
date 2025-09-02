$ dnf check-update  
$ sudo dnf update & sudo dnf  upgrade --skip-broken  
$ sudo dnf upgrade --skip-broken  
  
$ sudo cat /etc/passwd | grep my-user  
$ sudo useradd my-user  
$ sudo passwd my-user  
$ Password: **my-user123**  
$ mkdir ~/install  
  
  
  
   
# Установка Java  
  
скопировать jdk-17.0.8_linux-x64_bin.rpm в ~/install  
или wget [https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.rpm](https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.rpm)  
$ sudo rpm -i jdk-17.0.8_linux-x64_bin.rpm  
  
Если "из коробки"  
$ sudo dnf install java-17-openjdk-*  
  
```
KeyCloak 21.0.1. не работает с Java 21 !!!!

```

$ java -version  
$ sudo alternatives --config java  
  
Далее исправляем файлик **/etc/profile**  
$ sudo nano **/etc/profile**  
и вставляем:  
  

```

export JAVA_HOME=/usr/lib/jvm/java-17-openjdk-17.0.13.0.11-1.el7.x86_64/
export JRE_HOME=/usr/lib/jvm/java-17-openjdk-17.0.13.0.11-1.el7.x86_64/
export PATH=$PATH:/usr/lib/jvm/java-17-openjdk-17.0.13.0.11-1.el7.x86_64/bin/
export KEYCLOAK_ADMIN=admin
export KEYCLOAK_ADMIN_PASSWORD=admin_password
export JAVA_OPTS_APPEND="-Xms1024m -Xmx2048m"

```


$ sudo reboot now  
$ ls -la ${JAVA_HOME}  
  
# Установка KeyCloak   
  
$ sudo mkdir /opt/keycloak  
$ sudo chown -R my-user:my-user /opt/keycloak  
$ sudo unzip -d /opt/keycloak keycloak-21.0.1.zip  
$ cd /opt/keycloak/  
$ sudo mv ./keycloak-21.0.1/* .  
$ sudo rm -rf ./keycloak-21.0.1  
$ cd ..  
$ sudo chown -R my-user:my-user /opt/keycloak  
$ sudo nano **/etc/profile**  
и вставляем:  
  
```
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-21.0.5.0.11-1.el7.x86_64/
export JRE_HOME=/usr/lib/jvm/java-21-openjdk-21.0.5.0.11-1.el7.x86_64/
export PATH=$PATH:/usr/lib/jvm/java-21-openjdk-21.0.5.0.11-1.el7.x86_64/bin/
export KEYCLOAK_ADMIN=admin
export KEYCLOAK_ADMIN_PASSWORD=admin_password
export JAVA_OPTS_APPEND="-Xms1024m -Xmx2048m"
```

$ sudo reboot now  
  
## Задать максимальный размер хедерав quarkus.properties  
  
$ sudo nano /opt/keycloak/conf/quarkus.properties  
После открытия файла ввести:  
  
```
quarkus.http.limits.max-header-size=512K
```

сохранить и выйти.  
  
### перестартуем сервер и коннектимся заново  
  
$ env | grep KEY  
$ su - my-user  
$ cd /opt/keycloak/bin/  
$ ./kc.sh start-dev  
  
должен запуститься...  
  
[http://myserver:8080](http://myserver:8080/) - проверяем  
  
# Создаем Базу данных в PostgreSQL  
  
Идем на машину с PG - my-pg-server  
  
$ sudo su postgres  
$ psql  
  
/* Базу создавать так*/  
  
```
CREATE USER keycloak WITH ENCRYPTED PASSWORD 'keycloak_password';
CREATE DATABASE keycloak WITH OWNER keycloak;
GRANT ALL PRIVILEGES ON DATABASE keycloak TO keycloak;
/* коннектимся как пользователь keycloak*/
\c keycloak;
ALTER ROLE keycloak SET client_encoding TO 'utf8';
CREATE SCHEMA IF NOT EXISTS keycloak AUTHORIZATION keycloak;
GRANT ALL ON SCHEMA keycloak TO keycloak;
SET search_path to keycloak;

```

db: keycloak  
schema: keycloak  
user: keycloak  
password: keycloak_password  
  
## Изменяем конфигурацию KeyCloak   
  
$ sudo nano /opt/keycloak/conf/keycloak.conf  

```
db=postgres
db-schema=keycloak
db-username=keycloak
db-password=keycloak_password
db-url=jdbc:postgresql://my-pg-server/keycloak
health-enabled=true
metrics-enabled=true
https-certificate-file=${kc.home.dir}/conf/myserver.crt
https-certificate-key-file=${kc.home.dir}/conf/myserver.key
#proxy=reencrypt
#proxy=edge
#user=admin
#password=admin_password
hostname=myserver
```

## Подключение к PostgreSQL  
  
Запускаем - проверяем  
$ sudo ./kc.sh build --db=postgres  
  
Посмотреть конфигурацию  
$ sudo /opt/keycloak/bin/kc.sh show-config  
  
  
# Запуск и создание админа   
  
$ dnf list |grep w3m  
$ sudo dnf install -y w3m w3m-img  
$ w3m [http://localhost:8080](http://localhost:8080/)  
  
Вводим логин и пароль - это пароль админки!!!  
  
  
  
# Настройка режима "Продакшн"   

# Далее делаем автозапуск при старте системы  
  
$ sudo nano /etc/systemd/system/keycloak.service  
  
```
[Unit]
Description=Keycloak
After=network.target

[Service]
Type=simple
User=my-user
Group=my-user
EnvironmentFile=/opt/keycloak/conf/keycloak.conf
ExecStart=/opt/keycloak/bin/kc.sh start --log-level="DEBUG"
WorkingDirectory=/opt/keycloak
StandardOutput=journal
StandardError=inherit
LimitNOFILE=65535
LimitNPROC=4096
LimitAS=infinity
LimitFSIZE=infinity
TimeoutStopSec=0
KillSignal=SIGTERM
KillMode=process
SendSIGKILL=no
TimeoutStartSec=75

[Install]
WantedBy=multi-user.target

```

Вставляем:  
  
выходим с охранением!!!  
  
$ sudo systemctl daemon-reload  
$ sudo systemctl enable keycloak  
$ sudo systemctl start keycloak  
$ sudo systemctl status keycloak  
  
# Установка NGinx  
  
$ sudo dnf install nginx  
$ sudo systemctl enable nginx  
$ sudo systemctl start nginx  
$ sudo systemctl status nginx  
  
Создайте директорию и перенесите туда свои сертификаты  
  
$ sudo mkdir /etc/nginx/certs  
$ sudo cp <prerequire_path>/(Ваши сертификаты) ./  
  
sudo nano /etc/nginx/conf.d/keycloak.conf  
  
```
server {
 listen 80;
 listen [::]:80;
 server_name myserver;
 return 301 https://$server_name$request_uri;
}

server {

 listen 443 ssl;
 server_name myserver;
 ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
 ssl_session_cache shared:SSL:20m;
 ssl_session_timeout 15m;
 ssl_prefer_server_ciphers on;
 ssl_stapling on;

 ssl_certificate /etc/nginx/certs/myserver.crt; #Укажите путь до сертификатов
 ssl_certificate_key /etc/nginx/certs/myserver.key; #Укажите путь до сертификатов

 proxy_busy_buffers_size 512k;
 proxy_buffers 4 512k;
 proxy_buffer_size 512k;
 large_client_header_buffers 4 512k;
 access_log /var/log/nginx/kclk.access.log;
 error_log /var/log/nginx/kclk.error.log;
 client_max_body_size 0;
 proxy_read_timeout 300;
 proxy_connect_timeout 300;
 proxy_send_timeout 300;
	location / {
	 proxy_pass http://localhost:8080;
	 proxy_set_header Host $host;
	 proxy_set_header X-Real-IP $remote_addr;
	 proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
	 proxy_set_header X-Forwarded-Host $host;
	 proxy_set_header X-Forwarded-Server $host;
	 proxy_set_header X-Forwarded-Port $server_port;
	 proxy_set_header X-Forwarded-Proto $scheme;
	}
}

```

$ sudo systemctl restart nginx  
$ sudo systemctl status nginx  
# Настройка KeyCloak   
  
[http://myserver:8080/admin/](http://myserver:8080/admin/)  
  
создаем новый Realm  
  
my-solution  
  
Необходимо перейти по данному адресу. В данном адресе используется realm my-solution и client admin-panel.    
[http://myserver:8080/realms/my-solution/protocol/openid-connect/auth?client_id=admin-panel&response_mode=fragment&response_type=code](http://myserver:8080/realms/my-solution/protocol/openid-connect/auth?client_id=admin-panel&response_mode=fragment&response_type=code)  
  
И в сессиях внутри созданного realm будет создана сессия пользователя, под которым происходила авторизация. На скриншоте realm myserver, но у вас будет ваш созданный my-solution и ваш пользователь..  
  
## Проверка Realm   
  
[https://myserver/realms/my-solution/.well-known/openid-configuration](https://myserver/realms/my-solution/.well-known/openid-configuration)  
  
## Коннект   
  
[https://myserver:8080](https://myserver:8080)  
  
