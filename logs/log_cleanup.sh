#!/bin/bash

# === Настройки ===
LOG_DIR="/var/log"
DAYS_TO_KEEP=2
MAX_FILE_SIZE=1048576  # 1 MB (1024*1024) — файлы больше этого будут обрабатываться
MIN_FILE_SIZE=100      # 100 байт — файлы меньше этого пропускаются
LOG_FILE="/var/log/log_cleanup.log"
REPORT_FILE="/var/log/log_cleanup_report.log"
DRY_RUN=false
VERBOSE=false

# === Исключённые файлы ===
EXCLUDE_FILES=(
    "wtmp" "btmp" "lastlog" "tallylog" "faillog" "README"
)

# === Паттерны архивных файлов ===
ARCHIVE_PATTERNS=(
    "*.[0-9]"           # .1, .2, .3 ...
    "*.log.*"           # .log.1, .log.2.gz
    "*-????????"        # -20260315, -20260301
    "*.????????"        # log.20260314
    "*.log"             # .log (если не архив)
)

# === Проверка прав ===
if [[ $EUID -ne 0 ]]; then
    echo "? Ошибка: скрипт должен запускаться от root" >&2
    exit 1
fi

# === Установка режимов безопасности ===
set -euo pipefail
shopt -s nullglob  # Не расширять пустые шаблоны

# === Функции ===

# Проверка, исключён ли файл
is_excluded() {
    local base=$(basename "$1")
    for excl in "${EXCLUDE_FILES[@]}"; do
        [[ "$base" == "$excl" ]] && return 0
    done
    return 1
}

# Проверка, является ли файл архивом по паттерну
is_archive() {
    local fname=$(basename "$1")
    for pattern in "${ARCHIVE_PATTERNS[@]}"; do
        case "$fname" in
            $pattern) return 0 ;;
        esac
    done
    return 1
}

# Запись в лог
log() {
    local level="$1"
    local msg="$2"
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')
    echo "[$timestamp] [$level] $msg" >> "$LOG_FILE"
}

# Отправка уведомления (опционально)
notify() {
    local msg="$1"
    if command -v mail &>/dev/null; then
        echo "$msg" | mail -s "Log Cleanup Report" root
    elif command -v curl &>/dev/null; then
        # Пример для Telegram (требуется токен и chat_id)
        # curl -s -X POST "https://api.telegram.org/bot<TOKEN>/sendMessage" -d chat_id=<CHAT_ID> -d text="$msg"
        :
    fi
}

# === Проверка поддержки journalctl ===
check_journalctl() {
    if ! command -v journalctl &>/dev/null; then
        log "WARNING" "journalctl не найден. Очистка journald пропущена."
        return 1
    fi
    return 0
}

# === Очистка journald ===
cleanup_journal() {
    if ! check_journalctl; then
        return
    fi

    log "INFO" "Очистка journald: оставляем записи за последние $DAYS_TO_KEEP дней"

    # Попробуем сначала rotate, потом vacuum
    journalctl --rotate 2>/dev/null || log "WARNING" "Не удалось выполнить --rotate"
    journalctl --vacuum-time="${DAYS_TO_KEEP}days" 2>/dev/null || {
        log "ERROR" "Не удалось выполнить --vacuum-time=${DAYS_TO_KEEP}days"
        return 1
    }
    log "INFO" "journald очищен"
}

# === Основная очистка логов ===
cleanup_logs() {
    local now=$(date +%s)
    local cutoff=$((now - DAYS_TO_KEEP * 86400))
    local total_deleted=0
    local total_truncated=0
    local total_skipped=0
    local total_archives=0

    log "INFO" "Начинаем очистку в $LOG_DIR. Порог: $(date -d "@$cutoff" '+%Y-%m-%d %H:%M:%S')"

    # Используем find с -print0 для безопасной обработки имен
    find "$LOG_DIR" -path "./journal" -prune -o -type f -print0 | while IFS= read -r -d '' file; do
        # Убираем ./ из пути
        file="${file#$LOG_DIR/}"
        [[ -z "$file" ]] && continue

        # Проверка на исключения
        is_excluded "$file" && {
            log "DEBUG" "Пропускаем (исключено): $file"
            ((total_skipped++))
            return
        }

        # Проверка на существование файла
        [ -f "$file" ] || {
            log "DEBUG" "Файл не существует: $file"
            ((total_skipped++))
            return
        }

        # Получение времени изменения
        mtime=$(stat -c %Y "$file" 2>/dev/null) || {
            log "DEBUG" "Не удалось получить время: $file"
            ((total_skipped++))
            return
        }

        # Проверка на возраст
        if [[ $mtime -lt $cutoff ]]; then
            # Файл старше порога

            # Проверка размера
            size=$(stat -c %s "$file" 2>/dev/null || echo 0)
            if [[ $size -lt $MIN_FILE_SIZE ]]; then
                log "DEBUG" "Пропускаем (слишком маленький): $file (размер: $size байт)"
                ((total_skipped++))
                return
            fi

            # Проверка на архив
            if is_archive "$file"; then
                log "INFO" "?? УДАЛЯЕМ архив: $file (размер: $size байт, изменён: $(date -d "@$mtime" '+%Y-%m-%d %H:%M:%S'))"
                ((total_archives++))
                if [[ $DRY_RUN == false ]]; then
                    rm -f "$file" || log "ERROR" "Не удалось удалить: $file"
                fi
            else
                # Активный лог
                if [[ $size -gt 0 ]]; then
                    log "INFO" "?? ОЧИЩАЕМ активный лог: $file (размер: $size байт, изменён: $(date -d "@$mtime" '+%Y-%m-%d %H:%M:%S'))"
                    ((total_truncated++))
                    if [[ $DRY_RUN == false ]]; then
                        truncate -s 0 "$file" || log "ERROR" "Не удалось очистить: $file"
                    fi
                else
                    log "DEBUG" "Пропускаем (пустой): $file"
                    ((total_skipped++))
                fi
            fi
        else
            # Молодой файл — оставляем
            log "INFO" "? Оставляем (молодой): $file (размер: $size байт, изменён: $(date -d "@$mtime" '+%Y-%m-%d %H:%M:%S'))"
            ((total_skipped++))
        fi
    done

    # Итог
    echo "=== Очистка завершена ===" >> "$REPORT_FILE"
    echo "  Удалено архивов: $total_archives" >> "$REPORT_FILE"
    echo "  Очищено активных логов: $total_truncated" >> "$REPORT_FILE"
    echo "  Пропущено: $total_skipped" >> "$REPORT_FILE"
    echo "  Всего файлов: $((total_archives + total_truncated + total_skipped))" >> "$REPORT_FILE"
    echo "  Дата: $(date)" >> "$REPORT_FILE"
    echo "" >> "$REPORT_FILE"
}

# === Обработка аргументов ===
while [[ $# -gt 0 ]]; do
    case $1 in
        --dry-run)
            DRY_RUN=true
            VERBOSE=true
            shift
            ;;
        --verbose)
            VERBOSE=true
            shift
            ;;
        --days)
            DAYS_TO_KEEP="$2"
            shift 2
            ;;
        --help)
            echo "Использование: $0 [опции]"
            echo "  --dry-run    Тестовый режим (не удаляет файлы)"
            echo "  --verbose    Подробный вывод"
            echo "  --days N     Оставлять логи за последние N дней (по умолчанию 2)"
            echo "  --help       Показать эту справку"
            exit 0
            ;;
        *)
            echo "Неверный аргумент: $1" >&2
            exit 1
            ;;
    esac
done

# === Вывод настройки ===
if [[ $VERBOSE == true ]]; then
    echo "?? Настройки:"
    echo "  LOG_DIR: $LOG_DIR"
    echo "  DAYS_TO_KEEP: $DAYS_TO_KEEP"
    echo "  DRY_RUN: $DRY_RUN"
    echo "  MAX_FILE_SIZE: $MAX_FILE_SIZE"
    echo "  MIN_FILE_SIZE: $MIN_FILE_SIZE"
    echo "  EXCLUDE_FILES: ${EXCLUDE_FILES[*]}"
    echo "  ARCHIVE_PATTERNS: ${ARCHIVE_PATTERNS[*]}"
fi

# === Запуск ===
log "INFO" "Запуск скрипта очистки логов"
log "INFO" "Режим: $( [[ $DRY_RUN == true ]] && echo "тестовый" || echo "реальный" )"

# Очистка journald
cleanup_journal

# Очистка остальных логов
cleanup_logs

# Отправка отчета
if [[ $DRY_RUN == false ]]; then
    notify "Очистка логов завершена. Удалено: $total_archives архивов, очищено: $total_truncated логов."
fi

# Вывод итога
echo "? Очистка завершена."
echo "  Результаты: $REPORT_FILE"