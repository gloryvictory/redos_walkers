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
$ mkdir /data/pgdata/15/data
$ chown -R postgres.postgres /data/pgdata
$ systemctl edit postgresql-15.service 

```
[Service]
Environment=PGDATA=/data/pgdata/15/data
```

$ postgresql-15-setup initdb
$ systemctl enable postgresql-15.service --now
$ systemctl status postgresql-15.service
$ su - postgres
$ psql
$ ALTER USER postgres WITH ENCRYPTED PASSWORD 'postgres';
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



backup.sh

```
PGPASSWORD=postgres
export PGPASSWORD
dir1=/backup/`date +"%Y"`/
if [ ! -d $dir1 ]
then
mkdir $dir1
fi
dir2=/backup/`date +"%Y"`/`date +"%m"`/
if [ ! -d $dir2 ]
then
mkdir $dir2
fi
dir3=/backup/`date +"%Y"`/`date +"%m"`/`date +"%d"`/
if [ ! -d $dir3 ]
then
mkdir $dir3
fi

echo "Backup postgres" $2>> $dir3/log.txt
pg_dump --username "postgres" --role "postgres" --no-password -d postgres --format custom -Z 9 --blobs --section pre-data --section data --section post-data --encoding UTF8 --verbose > /backup/`date +"%Y"`/`date +"%m"`/`date +"%d"`/postgres.compressed 2>> $dir3/log.txt
echo "Backup test" $2>> $dir3/log.txt
pg_dump --username "postgres" --role "postgres" --no-password -d test --format custom -Z 9 --blobs --section pre-data --section data --section post-data --encoding UTF8 --verbose > /backup/`date +"%Y"`/`date +"%m"`/`date +"%d"`/test.compressed 2>> $dir3/log.txt
echo "Backup admin" $2>> $dir3/log.txt

```


backup_del.sh

```
date $2>>/backup/del.log
find /backup/ -maxdepth 4 -type f -mtime +60 -name '*.compressed' -exec echo {} \; -exec rm {} \; 2>> /backup/del.log
find /backup/ -maxdepth 4 -type f -mtime +60 -name 'log.txt' -exec echo {} \; -exec rm {} \;  $2>> /backup/del.log
```

backup_clear_log.sh

```
date $2>> /backup/clear_log.log
find /pgdata/15/data/log -maxdepth 1 -type f -mtime +21 -name '*.log' -exec echo {} \; -exec tar -rvf /pgdata/15/data/log/backup/backup_`date +%Y_%m_%d`.tar {} \; -exec rm {} \; 2>> /backup/clear_log.log
find /pgdata/15/data/log -maxdepth 1 -type f -mtime +21 -name '*.csv' -exec echo {} \; -exec tar -rvf /pgdata/15/data/log/backup/backup_`date +%Y_%m_%d`.tar {} \; -exec rm {} \; 2>> /backup/clear_log.log
find /pgdata/15/data/log/backup -maxdepth 1 -type f -mtime +60 -name '*.tar' -exec echo {} \; -exec rm {} \; 2>> /backup/clear_log.log

```