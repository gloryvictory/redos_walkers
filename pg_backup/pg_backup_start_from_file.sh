#!/bin/bash

set -euo pipefail

# === Настройки ===
PGUSER="postgres"
PGPASSWORD="postgrespwd"
export PGPASSWORD

# Путь к файлу со списком баз
DB_LIST_FILE="backup_databases.txt"

# Путь для бэкапов
BASE_DIR="/data2/backup"
DATE_Y=$(date +"%Y")
DATE_M=$(date +"%m")
DATE_D=$(date +"%d")
BACKUP_DIR="$BASE_DIR/$DATE_Y/$DATE_M/$DATE_D"
LOG_FILE="$BACKUP_DIR/log.txt"

# Создаём директорию
mkdir -p "$BACKUP_DIR"

# Функция логирования
log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') - $*" | tee -a "$LOG_FILE"
}

log "=== Начало резервного копирования (список из $DB_LIST_FILE) ==="

# Проверяем существование файла
if [ ! -f "$DB_LIST_FILE" ]; then
    log "ОШИБКА: Файл со списком баз не найден: $DB_LIST_FILE"
    exit 1
fi

# Читаем файл построчно
while IFS= read -r line || [ -n "$line" ]; do
    # Пропускаем пустые строки и комментарии (если нужно)
    [[ -z "$line" ]] && continue
    [[ "$line" =~ ^[[:space:]]*# ]] && continue

    DB_NAME=$(echo "$line" | xargs)  # удаляем лишние пробелы по краям

    if [ -z "$DB_NAME" ]; then
        continue
    fi

    log "Резервное копирование базы: $DB_NAME"

    OUTPUT_FILE="$BACKUP_DIR/${DB_NAME}.compressed"

    if pg_dump \
        --username="$PGUSER" \
        --role="$PGUSER" \
        --no-password \
        --dbname="$DB_NAME" \
        --format=custom \
        --compress=9 \
        --blobs \
        --section=pre-data \
        --section=data \
        --section=post-data \
        --encoding=UTF8 \
        --verbose \
        > "$OUTPUT_FILE" 2>> "$LOG_FILE"
    then
        log "Успешно: $DB_NAME → $OUTPUT_FILE"
    else
        log "ОШИБКА при резервном копировании: $DB_NAME"
        # Продолжаем, даже если одна БД не скопировалась
    fi
done < "$DB_LIST_FILE"

log "=== Резервное копирование завершено ==="