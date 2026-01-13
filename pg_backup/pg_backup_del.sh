date $2>>/data1/backup/del.log
find /data1/backup/ -maxdepth 4 -type f -mtime +60 -name '*.compressed' -exec echo {} \; -exec rm {} \; 2>> /data1/backup/del.log
find /data1/backup/ -maxdepth 4 -type f -mtime +60 -name 'log.txt' -exec echo {} \; -exec rm {} \;  $2>> /data1/backup/del.log
