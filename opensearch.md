# Установка под REDOS 7.x


$ dnf check-update  
$ sudo dnf update & sudo dnf  upgrade --skip-broken  
$ sudo dnf upgrade --skip-broken  

$ sudo cat /etc/passwd | grep my-user  
$ sudo useradd my-user  
$ sudo passwd my-user  
$ Password: **my-user123**  
$ sudo mkdir /install  
$ sudo chmod 777 /install  
$ cd /install  
$ sudo cp /etc/opensearch/opensearch.yml{,.bak}  

# Предустановка 

Отключите memory paging и swapping для ускорения работы сервисов  
$ sudo swapoff -a  

## Изменить sysctl 

Увеличьте количество memory maps доступных для Opensearch  
$ sudo nano /etc/sysctl.conf  
необходимо добавить эту строчку и сохранить изменения  

$ sysctl -a | grep max_map_count  

```
vm.max_map_count=262144
```

Перезагрузить базовые параметры используя sysctl  

$ sudo sysctl -p  

Проверить что изменения действительно добавлены  
$ cat /proc/sys/vm/max_map_count  

##selinux

Обязательно потребуется отключение **selinux** командой:  

$ sudo sed -i 's/SELINUX=enforcing/SELINUX=disabled/' /etc/selinux/config  
$ sudo setenforce 0  


# Установка  OpenSearch из rpm

$ cd /install  

```
export OPENSEARCH_INITIAL_ADMIN_PASSWORD=<custom-admin-password>
sudo env OPENSEARCH_INITIAL_ADMIN_PASSWORD=<custom-admin-password> 
```
$ sudo rpm -ivh opensearch-3.2.0-linux-x64.rpm  
$ sudo rpm -ivh opensearch-dashboards-3.2.0-linux-x64.rpm  


$ more /var/log/opensearch/install_demo_configuration.log  

```
OpenSearch Security Demo Installer  
Warning: Do not use on production or public reachable systems **  
OpenSearch install type: rpm/deb on Linux 6.1.110-1.el7.3.x86_64 amd64  
OpenSearch config dir: /etc/opensearch/  
OpenSearch config file: /etc/opensearch/opensearch.yml  
OpenSearch bin dir: /usr/share/opensearch/bin/  
OpenSearch plugins dir: /usr/share/opensearch/plugins/  
OpenSearch lib dir: /usr/share/opensearch/lib/  
Detected OpenSearch Version: 3.2.0  
Detected OpenSearch Security Version: 3.2.0.0  
No custom admin password found. Please provide a password via the environment variable OPENSEARCH_INITIAL_ADMIN_PASSWORD  
```

# Установка  OpenSearch из коробки


$ sudo env OPENSEARCH_INITIAL_ADMIN_PASSWORD=my-password  
$ sudo dnf list | grep opensearch  
$ sudo dnf install opensearch.x86_64  
$ /usr/bin/opensearch  
$ sudo systemctl daemon-reload  
$ sudo systemctl enable opensearch --now  
$ sudo systemctl start opensearch
$ sudo systemctl status opensearch  
$ sudo mkdir /data/opensearch  
$ sudo chown -R opensearch:opensearch /data/opensearch  

# Изменяем настройки  OpenSearch

$ sudo cp /etc/opensearch/opensearch.yml{,.bak}  
$ sudo nano /etc/opensearch/opensearch.yml  

Правим Содержание /etc/opensearch/opensearch.yml  

изменяем   

```
path.data: /data/opensearch
path.logs: /data/opensearch/log

discovery.type: single-node
network.host: 0.0.0.0
http.port: 9200

#если надо отключить https на уровне плагина
plugins.security.disabled: false

discovery.seed_hosts: ["<server_name>","127.0.0.1", "[::1]"]
plugins.security.ssl.transport.pemcert_filepath: /etc/opensearch/<my_org>.crt
plugins.security.ssl.transport.pemkey_filepath: /etc/opensearch/<my_org>-pkcs8.key
plugins.security.ssl.transport.pemtrustedcas_filepath: /etc/opensearch/<my_org>-root-ca.crt
plugins.security.ssl.transport.enforce_hostname_verification: false
plugins.security.ssl.http.enabled: true
plugins.security.ssl.http.pemcert_filepath: /etc/opensearch/<my_org>.crt
plugins.security.ssl.http.pemkey_filepath: /etc/opensearch/<my_org>-pkcs8.key
plugins.security.ssl.http.pemtrustedcas_filepath: /etc/opensearch/<my_org>-root-ca.crt
plugins.security.allow_unsafe_democertificates: false
plugins.security.allow_default_init_securityindex: true
plugins.security.audit.type: internal_opensearch
plugins.security.enable_snapshot_restore_privilege: true
plugins.security.check_snapshot_restore_write_privileges: true
plugins.security.restapi.roles_enabled: ["all_access", "security_rest_api_access"]
plugins.security.authcz.admin_dn:
  - 'CN=<my_org> Class 1 Issuing SubCA 2,DC=tm,DC=<my_org>,DC=int'
plugins.security.nodes_dn:
#  - 'CN=<server_name>,OU=IT,O=JSC <my_org>,C=RU'
  - 'CN=<server_name>,OU=NTC,O=<my_org>,L=TMN,ST=TMN,C=RU'

```

$ sudo systemctl restart opensearch.service  

$ curl -X GET [https://localhost:9200](https://localhost:9200/) -u 'admin:password' --insecure  

```
curl -X GET http://localhost:9200 -u admin:password -k
 
curl -X GET https://localhost:9200 -u admin:password -k --insecure

```

Посмотреть какие плагины  
```
curl http://localhost:9200/_cat/plugins?v -u admin:password -k
```

------------------------------------------------------------------------

# Установка Java 

скопировать jdk-17.0.8_linux-x64_bin.rpm в ~/install  
или wget [https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.rpm](https://download.oracle.com/java/17/latest/jdk-17_linux-x64_bin.rpm)  
$ sudo rpm -ivh jdk-17.0.8_linux-x64_bin.rpm  


$ sudo dnf install openjdk   
$ java -version  
$ sudo alternatives --config java  

Далее исправляем файлик **/etc/profile**

$ sudo nano **/etc/profile**  

и вставляем:  
```
export OPENSEARCH_JAVA_HOME=/usr/share/opensearch/jdk
export JAVA_HOME=/usr/lib/jvm/java-21-openjdk-21.0.7.0.6-1.el7.x86_64
export JRE_HOME=/usr/lib/jvm/java-21-openjdk-21.0.7.0.6-1.el7.x86_64
export PATH=$PATH:/usr/lib/jvm/java-21-openjdk-21.0.7.0.6-1.el7.x86_64/bin
```

$ sudo reboot now  
$ ls -la ${JAVA_HOME}  

Если нужно том можно добавить или уменьшить JVM heap size  
$ sudo nano /etc/opensearch/jvm.options  
 
```
-Xms4g
-Xmx4g
```



### обновления пароля пользователя admin и kibanaserver 

$ cd /usr/share/opensearch/plugins/opensearch-security/tools  
$ OPENSEARCH_JAVA_HOME=/usr/share/opensearch/jdk ./hash.sh  
После генерации пароля нужно скопировать созданный хеш-ключ.  

$ sudo nano /etc/opensearch/opensearch-security/internal_users.yml  

и изменяем хэш для пользователя admin - В поле «hash» в кавычки для пользователя admin вводим скопированный хеш-ключ.  
И Запускаем:   
```
$ OPENSEARCH_JAVA_HOME=/usr/share/opensearch/jdk ./securityadmin.sh -cd /etc/opensearch/opensearch-security/ -cacert /etc/opensearch/root-ca.pem -cert /etc/opensearch/admin.pem -key /etc/opensearch/admin-key.pem -icl -nhnv
```


$ sudo systemctl restart opensearch  
$ sudo usermod -aG opensearch $USER  
$ sudo nano /usr/lib/systemd/system/opensearch.service  

Добавить в секцию "[Service]"  

```
[Service]
Restart=always
```

$ sudo systemctl daemon-reload  
$ sudo systemctl restart opensearch  


$ cd /usr/share/opensearch/plugins/opensearch-security/tools  

$ sudo OPENSEARCH_JAVA_HOME=/usr/share/opensearch/jdk ./securityadmin.sh -cd /etc/opensearch/opensearch-security/ -cacert /etc/opensearch/root-ca.pem -cert /etc/opensearch/admin.pem -key /etc/opensearch/admin-key.pem -icl -nhnv  

$ curl [https://localhost:9200](https://localhost:9200/) -u admin:yournewpassword -k  

$ curl [https://localhost:9200/_cat/plugins?v](https://localhost:9200/_cat/plugins?v) -u admin:adminpwd -k  

-----------------------------------------------------------------------------------------------------------------------------------

# Установка OpenSearch-Dashboards 

$ sudo dnf install opensearch-dashboards  
$ sudo systemctl daemon-reload  
$ sudo systemctl enable opensearch-dashboards --now  
$ sudo systemctl daemon-reload  
$ sudo systemctl start opensearch-dashboards  
$ sudo systemctl status opensearch-dashboards  
$ /usr/share/opensearch-dashboards/bin/opensearch-dashboards-plugin list  



# При отсутствии ssl

```
server.ssl.enabled: false
opensearch_security.multitenancy.enabled: true
opensearch_security.multitenancy.tenants.preferred: ["Private", "Global"]
opensearch_security.readonly_mode.roles: [kibana_read_only]
```

# Используйте эту настройку если не включен ssl

```
opensearch_security.cookie.secure: false
```


Можно сразу запустить сервис с помощью команды ..../bin/opensearch-dashboards  
После запуска, можно его выключить(ctrl+C), т.к. будет осуществляться запуск через system.  

Создайте пользователя ...  

$ sudo systemctl daemon-reload  
$ sudo systemctl enable opensearch-dashboards.service  
$ sudo systemctl start opensearch-dashboards.service  
$ sudo systemctl status opensearch-dashboards.service  

### Копируем корневые сертификаты 

$ cd /etc/opensearch-dashboards/  
$ sudo cp /etc/opensearch/root-ca* ./  
/etc/opensearch-dashboards/root-ca-key.pem  
/etc/opensearch-dashboards/root-ca.pem  

$ sudo chown opensearch-dashboards:opensearch-dashboards root-ca-key.pem root-ca.pem root-ca.srl  

$ sudo cp /etc/opensearch-dashboards/opensearch_dashboards.yml{,.bak}  
$ sudo nano /etc/opensearch-dashboards/opensearch_dashboards.yml  

Вставляем:

```
server.port: 5601
server.host: 0.0.0.0

opensearch.hosts: [https://localhost:9200]
opensearch.ssl.verificationMode: certificate
opensearch.username: admin
opensearch.password: password
opensearch.requestHeadersWhitelist: [authorization, securitytenant]

opensearch_security.multitenancy.enabled: true
opensearch_security.multitenancy.tenants.preferred: [Private, Global]
opensearch_security.readonly_mode.roles: [kibana_read_only]
# Use this setting if you are running opensearch-dashboards without https
opensearch_security.cookie.secure: true
server.ssl.enabled: true

server.ssl.certificate: /etc/opensearch-dashboards/<my_org>.crt
server.ssl.key: /etc/opensearch-dashboards/<my_org>.key
opensearch.ssl.certificateAuthorities: [ "/etc/opensearch-dashboards/<my_org>-root-ca.crt" ]
```


должен быть логин пароль из настроек opensearch.service  


# Use this setting if you are running opensearch-dashboards without https  

```
opensearch_security.cookie.secure: false
server.ssl.enabled: true
server.ssl.certificate: /etc/opensearch-dashboards/root-ca.pem
server.ssl.key: /etc/opensearch-dashboards/root-ca-key.pem

```

$ sudo systemctl restart opensearch-dashboards.service  

Открываем браузер:  

[http://<my_org>.ru:5601](http://<my_org>.ru:5601/)

[https://<my_org>.ru:5601](https://<my_org>.ru:5601/)

# Установка nginx 

$ sudo dnf install -y nginx  
$ sudo systemctl enable nginx  
$ sudo systemctl is-enabled nginx  
$ sudo systemctl status nginx  
$ sudo setsebool -P httpd_can_network_connect 1  
$ cp /etc/nginx/sites-enabled/default /etc/nginx/sites-enabled/default.bak  
$ sudo nano /etc/nginx/conf.d/elastic.conf  

```
server {
        listen 80;
        listen [::]:80;
        server_name <server_name>;
        return 301 https://$server_name$request_uri;
}
server{
        listen 443 ssl;
        server_name <server_name> ;
        ssl_protocols TLSv1 TLSv1.1 TLSv1.2 TLSv1.3;
        ssl_session_cache shared:SSL:20m;
        ssl_session_timeout 15m;
        ssl_prefer_server_ciphers on;
        ssl_stapling on;

        ssl_certificate /etc/nginx/certs/<my_org>.crt; #Укажите путь до сертификатов
        ssl_certificate_key /etc/nginx/certs/<my_org>.key; #Укажите путь до сертификатов

        proxy_busy_buffers_size 512k;
        proxy_buffers 4 512k;
        proxy_buffer_size 512k;
        large_client_header_buffers 4 512k;
        access_log /var/log/nginx/access.log;
        error_log /var/log/nginx/error.log;
        client_max_body_size 0;
        proxy_read_timeout 300;
        proxy_connect_timeout 300;
        proxy_send_timeout 300;

        location / {
         proxy_pass https://localhost:5601;
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


###  можно пользоваться:
[https://habr.com/ru/articles/662527/](https://habr.com/ru/articles/662527/)   
[https://selectel.ru/blog/install-nginx/](https://selectel.ru/blog/install-nginx/)  


### Создание самоподписных сертификатов для работы через https 

```
$ cd /etc/opensearch
$ sudo mkdir old
$ sudo *.pem old
$ sudo mv *.pem old
$ sudo openssl genrsa -out root-ca-key.pem 2048
$ sudo openssl genrsa -out admin-key-temp.pem 2048
$ sudo openssl pkcs8 -inform PEM -outform PEM -in admin-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out admin-key.pem
$ sudo openssl req -new -key admin-key.pem -subj "/C=CA/ST=ONTARIO/L=TORONTO/O=ORG/OU=UNIT/CN=A" -out admin.csr
$ sudo openssl x509 -req -in admin.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out admin.pem -days 730
$ sudo openssl genrsa -out node1-key-temp.pem 2048
$ sudo openssl pkcs8 -inform PEM -outform PEM -in node1-key-temp.pem -topk8 -nocrypt -v1 PBE-SHA1-3DES -out node1-key.pem
$ sudo openssl req -new -key node1-key.pem -subj "/C=CA/ST=ONTARIO/L=TORONTO/O=ORG/OU=UNIT/CN=node1.dns.a-record" -out node1.csr
$ sudo sh -c 'echo subjectAltName=DNS:node1.dns.a-record > node1.ext'
$ sudo openssl x509 -req -in node1.csr -CA root-ca.pem -CAkey root-ca-key.pem -CAcreateserial -sha256 -out node1.pem -days 730 -extfile node1.ext
$ sudo rm -f *temp.pem *csr *ext
$ sudo chown opensearch:opensearch admin-key.pem admin.pem node1-key.pem node1.pem root-ca-key.pem root-ca.pem root-ca.srl
$ echo "plugins.security.ssl.transport.pemcert_filepath: /etc/opensearch/node1.pem" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo "plugins.security.ssl.transport.pemkey_filepath: /etc/opensearch/node1-key.pem" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo "plugins.security.ssl.transport.pemtrustedcas_filepath: /etc/opensearch/root-ca.pem" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo "plugins.security.ssl.http.enabled: true" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo "plugins.security.ssl.http.pemcert_filepath: /etc/opensearch/node1.pem" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo "plugins.security.ssl.http.pemkey_filepath: /etc/opensearch/node1-key.pem" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo "plugins.security.ssl.http.pemtrustedcas_filepath: /etc/opensearch/root-ca.pem" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo "plugins.security.allow_default_init_securityindex: true" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo "plugins.security.authcz.admin_dn:" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo " - 'CN=A,OU=UNIT,O=ORG,L=TORONTO,ST=ONTARIO,C=CA'" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo "plugins.security.nodes_dn:" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo " - 'CN=node1.dns.a-record,OU=UNIT,O=ORG,L=TORONTO,ST=ONTARIO,C=CA'" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo "plugins.security.audit.type: internal_opensearch" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo "plugins.security.enable_snapshot_restore_privilege: true" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo "plugins.security.check_snapshot_restore_write_privileges: true" | sudo tee -a /etc/opensearch/opensearch.yml
$ echo "plugins.security.restapi.roles_enabled: [\"all_access\", \"security_rest_api_access\"]" | sudo tee -a /etc/opensearch/opensearch.yml

Добавляем доверие для самозаверяющего сертификата:

$ sudo cp /etc/opensearch/root-ca.pem /etc/pki/ca-trust/source/anchors/
$ sudo update-ca-trust

```

## Настройка IPtables

$ sudo systemctl stop iptables  
$ sudo iptables -A INPUT -p tcp --dport 9200 -j ACCEPT  
$ sudo iptables -A INPUT -p tcp --dport 5601 -j ACCEPT  
$ sudo systemctl restart iptables  
