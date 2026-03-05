date $2>>/data/backup/deleted_backups.log
find /data/backup/ -maxdepth 4 -type f -mtime +60 -name '*.compressed' -exec echo {} \; -exec rm {} \; 2>> /data/backup/del.log
find /data/backup/ -maxdepth 4 -type f -mtime +60 -name 'log.txt' -exec echo {} \; -exec rm {} \;  $2>> /data/backup/del.log
