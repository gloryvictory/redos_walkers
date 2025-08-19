$ dnf check-update
$ sudo dnf update & sudo dnf  upgrade --skip-broken
$ sudo dnf upgrade --skip-broken
$ sudo cat /etc/passwd | grep my-user
$ sudo useradd my-user
$ sudo passwd my-user
Password: my-user123 (for example)
$ mkdir ~/install
$ cd ~/install
$ sudo su -  
$ dnf install postgresql15-server  
$ dnf install postgresql15-contrib  
$ dnf install postgresql15-devel  
$ dnf install cmake  
$ dnf install make  
$ dnf install gcc  
$ dnf install libxml2, xml2-config, libxml2-devel  
$ dnf install gdal, gdal-devel  
$ dnf install boost, boost-devel
$ mkdir /data1/pgdata/15/data
$ chown -R postgres.postgres /data1/pgdata
$ systemctl edit postgresql-15.service 

```
[Service]
Environment=PGDATA=/data1/pgdata/15/data
```

$ postgresql-15-setup initdb
$ systemctl enable postgresql-15.service --now
$ systemctl status postgresql-15.service
$ su - postgres
$ psql
$ ALTER USER postgres WITH ENCRYPTED PASSWORD 'postgres123';
$ systemctl restart postgresql-15.service
$ yum remove minizip
$ yum install postgis-pgsql15
$ su - postgres
$ psql
$ CREATE EXTENSION pg_stat_statements;
$ CREATE EXTENSION postgis;
$ systemctl stop postgresql-15.service
$ Подкидываем фалы параметров.
$ Меняем права этим файлам
$ chown postgres.postgres pg_hba.conf
$ chown postgres.postgres postgresql.conf
$ chown postgres.postgres postgresql.auto.conf

Меняем в postgresql.conf

```
dynamic_shared_memory_type = posix  
lc_messages = 'ru_RU.UTF-8'  
lc_monetary = 'ru_RU.UTF-8'  
lc_numeric = 'ru_RU.UTF-8'  
lc_time = 'ru_RU.UTF-8'
```

Собираем недостающие расширения
a. h3-pg-main 
cmake -B build -DCMAKE_BUILD_TYPE=Release
cmake --build build
cmake --install build --component h3-pg-main
----Во время сборки cmake попытается скачать файл, качаем вручную, переименовываем и подкидываем в нужную директорию(видно в логе), после чего опять собираем

b. pointcloud
./autogen.sh
./configure
make install

c. pgrouting
cmake ..
make
make install

d. pgsql_ogr_fdw_master
make
make install


```
CREATE EXTENSION IF NOT EXISTS postgis SCHEMA public;  
CREATE EXTENSION IF NOT EXISTS address_standardizer SCHEMA public;  
CREATE EXTENSION IF NOT EXISTS fuzzystrmatch SCHEMA public;  
CREATE EXTENSION IF NOT EXISTS h3 SCHEMA public;  
CREATE EXTENSION IF NOT EXISTS ogr_fdw SCHEMA public;  
CREATE EXTENSION IF NOT EXISTS pgrouting SCHEMA public;  
CREATE EXTENSION IF NOT EXISTS pointcloud SCHEMA public;  
CREATE EXTENSION IF NOT EXISTS pointcloud_postgis SCHEMA public;  
CREATE EXTENSION IF NOT EXISTS postgis_raster SCHEMA public;  
CREATE EXTENSION IF NOT EXISTS postgis_sfcgal SCHEMA public;  
CREATE EXTENSION IF NOT EXISTS h3_postgis SCHEMA public;  
```

#Восстанавливаем базы
$ su - postgres
$ pg_restore -d postgres -v postgres_backup.compressed



postgresql.conf

```

listen_addresses = '*'          # what IP address(es) to listen on;
log_destination = 'csvlog' 

logging_collector = on          # Enable capturing of stderr, jsonlog,
log_file_mode = 0640                    # creation mode for log files,
log_line_prefix='%t:%r:%u@%d:[%p]:%c:%e:%v:%x '
log_timezone = 'Asia/Yekaterinburg'
datestyle = 'iso, dmy'
timezone = 'Asia/Yekaterinburg'


lc_messages = 'ru_RU.UTF-8'
lc_monetary = 'ru_RU.UTF-8'
lc_numeric = 'ru_RU.UTF-8'
lc_time = 'ru_RU.UTF-8'


#lc_messages = 'Russian_Russia.1251'                    # locale for system error message
#lc_monetary = 'Russian_Russia.1251'                    # locale for monetary formatting
#lc_numeric = 'Russian_Russia.1251'                     # locale for number formatting
#lc_time = 'Russian_Russia.1251'                                # locale for time formatting

# default configuration for text search
default_text_search_config = 'pg_catalog.russian'
```

pg_hba.conf

```
host    all             all             all                     scram-sha-256

```