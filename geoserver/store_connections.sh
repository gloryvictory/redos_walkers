#!/bin/bash

GEOSERVER_URL="${GEOSERVER_URL:-http://localhost:8080/geoserver}"
GEOSERVER_WORKSPACES_DIR="${GEOSERVER_WORKSPACES_DIR:-/geoserver/data_dir/workspaces}"
GEOSERVER_USER="${GEOSERVER_USER:-admin}"
GEOSERVER_PASS="${GEOSERVER_PASS:-geoserver}"

# можно указать пароли к бд тут, либо в отдельном файле
declare -A PASSWORDS=(
  ["bd1"]="bd1_pwd"
  ["bd2"]="bd2_pwd"
  ["bd2"]="bd3_pwd"
)

update_datastore() {
    local workspace="$1"
    local datastore="$2"

    local xml_data

    local xml_file="$GEOSERVER_WORKSPACES_DIR/$workspace/$datastore/datastore.xml"

    if [ ! -f "$xml_file" ]; then
        echo "  Ошибка: файл конфигурации $xml_file не найден для хранилища $datastore"
        return 1
    fi

    if ! xml_data=$(parse_datastore_xml "$xml_file") || [ -z "$xml_data" ]; then
        echo "  Ошибка: не удалось прочитать конфигурацию из XML"
        return 1
    fi

    IFS='|' read -r host port database schema user dbtype namespace evictor_run_periodicity max_open_prepared_statements encode_functions batch_insert_size prepared_statements loose_bbox ssl_mode estimated_extends fetch_size expose_primary_keys validate_connections support_geometry_simplification connection_timeout create_database simplify_method min_connections max_connections evictor_tests_per_run test_while_idle max_connection_idle_time <<< "$xml_data"

    if [[ ${PASSWORDS["$database"]+_} ]]; then
        password=${PASSWORDS["$database"]}
    else
        echo "  Пароль для базы данных $database хранилища $datastore не задан, его можно будет обновить в ручную"
    fi

    cat > /tmp/datastore_update.json << EOF
{
  "dataStore": {
    "name": "$datastore",
    "enabled": true,
    "connectionParameters": {
      "host": "$host",
      "port": $port,
      "database": "$database",
      "schema": "$schema",
      "user": "$user",
      "passwd": "$password",
      "dbtype": "$dbtype",
      "namespace": "$namespace",
      "Evictor run periodicity": "$evictor_run_periodicity",
      "Max open prepared statements": "$max_open_prepared_statements",
      "encode functions": "$encode_functions",
      "Batch insert size": "$batch_insert_size",
      "preparedStatements": "$prepared_statements",
      "Loose bbox": "$loose_bbox",
      "SSL mode": "$ssl_mode",
      "Estimated extends": "$estimated_extends",
      "fetch size": "$fetch_size",
      "Expose primary keys": "$expose_primary_keys",
      "validate connections": "$validate_connections",
      "Support on the fly geometry simplification": "$support_geometry_simplification",
      "Connection timeout": "$connection_timeout",
      "create database": "$create_database",
      "Method used to simplify geometries": "$simplify_method",
      "min connections": "$min_connections",
      "max connections": "$max_connections",
      "Evictor tests per run": "$evictor_tests_per_run",
      "Test while idle": "$test_while_idle",
      "Max connection idle time": "$max_connection_idle_time"
    }
  }
}
EOF

    response=$(curl -u "$GEOSERVER_USER:$GEOSERVER_PASS" \
        -X PUT \
        -H "Content-Type: application/json" \
        -H "accept: application/json" \
        -d @/tmp/datastore_update.json \
        -w "\nHTTP статус: %{http_code}" \
        -s "$GEOSERVER_URL/rest/workspaces/$workspace/datastores/$datastore")

    http_code=$(echo "$response" | tail -n1 | cut -d' ' -f3)
    response_body=$(echo "$response" | sed '$d')

    if [ "$http_code" -eq 200 ]; then
        echo "  ✓ Успешно обновлено"
        if [ -n "$response_body" ]; then
            echo "  Ответ сервера:"
            echo "$response_body"
    fi
    else
        echo "  Ошибка HTTP $http_code"
        echo "  Ответ сервера:"
        echo "$response_body"
        return 1
    fi
}

show_help() {
    cat << EOF
Использование: $0 [ОПЦИИ]

Обновление хоста хранилищ Geoserver.

Опции:
  -h, --help                Показать эту справку
  -u, --url URL             URL GeoServer (по умолчанию: $GEOSERVER_URL)
  -d, --dir DIR             Директория с workspace (по умолчанию: $GEOSERVER_WORKSPACES_DIR)
  --user USER               Имя пользователя GeoServer (по умолчанию: $GEOSERVER_USER)
  --pass PASS               Пароль GeoServer (по умолчанию: $GEOSERVER_PASS)
  --password-file FILE      Файл с паролями для БД в формате KEY=VALUE

Формат файла с паролями (KEY=VALUE):
  postgres=postgres
  db=secret123

Если файл с паролями отсутствует, то в качестве пароля используется пустая строка

Пример комманды:
./update_datastore_passwords.sh --dir opt/geoserver/data_dir/workspaces --password-file passwords
EOF
}

load_passwords_from_file() {
    local file="$1"

    if [ ! -f "$file" ]; then
        echo "ОШИБКА: Файл с паролями '$file' не найден"
        exit 1
    fi

    echo "Загрузка паролей из файла: $file"

    while IFS='=' read -r key value || [ -n "$key" ]; do
        [[ "$key" =~ ^[[:space:]]*# ]] && continue
        [[ -z "$key" ]] && continue

        key=$(echo "$key" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
        value=$(echo "$value" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

        if [ -n "$key" ] && [ -n "$value" ]; then
            PASSWORDS["$key"]="$value"
        fi
    done < "$file"
}

POSITIONAL_ARGS=()

while [[ $# -gt 0 ]]; do
    case $1 in
        -h|--help)
            show_help
            exit 0
            ;;
        -u|--url)
            GEOSERVER_URL="$2"
            shift 2
            ;;
        -d|--dir)
            GEOSERVER_WORKSPACES_DIR="$2"
            shift 2
            ;;
        --user)
            GEOSERVER_USER="$2"
            shift 2
            ;;
        --pass)
            GEOSERVER_PASS="$2"
            shift 2
            ;;
        --password-file)
            load_passwords_from_file "$2"
            shift 2
            ;;
        *)
            POSITIONAL_ARGS+=("$1")
            shift
            ;;
    esac
done

set -- "${POSITIONAL_ARGS[@]}"

find_and_update_datastores() {
    echo "Поиск хранилищ для обновления..."

    find "$GEOSERVER_WORKSPACES_DIR" -name "datastore.xml" -type f | while read xml_file; do
        workspace=$(basename "$(dirname "$(dirname "$xml_file")")")
        datastore=$(basename "$(dirname "$xml_file")")

        echo "Обновление хранилища: $datastore"
        update_datastore "$workspace" "$datastore"
    done
}

extract_xml_value() {
    local xml_file="$1"
    local key="$2"

    grep -o "<entry key=\"$key\">[^<]*</entry>" "$xml_file" | sed "s/.*>\(.*\)<.*/\1/"
}

parse_datastore_xml() {
    local xml_file="$1"

    local host port database schema user dbtype namespace
    local evictor_run_periodicity max_open_prepared_statements encode_functions
    local batch_insert_size prepared_statements loose_bbox ssl_mode estimated_extends
    local fetch_size expose_primary_keys validate_connections support_geometry_simplification
    local connection_timeout create_database simplify_method min_connections max_connections
    local evictor_tests_per_run test_while_idle max_connection_idle_time

    if [ ! -f "$xml_file" ]; then
        echo "  Ошибка: файл $xml_file не найден"
        return 1
    fi

    host=$(extract_xml_value "$xml_file" "host")
    port=$(extract_xml_value "$xml_file" "port")
    database=$(extract_xml_value "$xml_file" "database")
    schema=$(extract_xml_value "$xml_file" "schema")
    user=$(extract_xml_value "$xml_file" "user")
    dbtype=$(extract_xml_value "$xml_file" "dbtype")

    evictor_run_periodicity=$(extract_xml_value "$xml_file" "Evictor run periodicity")
    max_open_prepared_statements=$(extract_xml_value "$xml_file" "Max open prepared statements")
    encode_functions=$(extract_xml_value "$xml_file" "encode functions")
    batch_insert_size=$(extract_xml_value "$xml_file" "Batch insert size")
    prepared_statements=$(extract_xml_value "$xml_file" "preparedStatements")
    loose_bbox=$(extract_xml_value "$xml_file" "Loose bbox")
    ssl_mode=$(extract_xml_value "$xml_file" "SSL mode")
    estimated_extends=$(extract_xml_value "$xml_file" "Estimated extends")
    fetch_size=$(extract_xml_value "$xml_file" "fetch size")
    expose_primary_keys=$(extract_xml_value "$xml_file" "Expose primary keys")
    validate_connections=$(extract_xml_value "$xml_file" "validate connections")
    support_geometry_simplification=$(extract_xml_value "$xml_file" "Support on the fly geometry simplification")
    connection_timeout=$(extract_xml_value "$xml_file" "Connection timeout")
    create_database=$(extract_xml_value "$xml_file" "create database")
    simplify_method=$(extract_xml_value "$xml_file" "Method used to simplify geometries")
    min_connections=$(extract_xml_value "$xml_file" "min connections")
    max_connections=$(extract_xml_value "$xml_file" "max connections")
    evictor_tests_per_run=$(extract_xml_value "$xml_file" "Evictor tests per run")
    test_while_idle=$(extract_xml_value "$xml_file" "Test while idle")
    max_connection_idle_time=$(extract_xml_value "$xml_file" "Max connection idle time")

    echo "${host}|${port}|${database}|${schema}|${user}|${dbtype}|${namespace}|${evictor_run_periodicity}|${max_open_prepared_statements}|${encode_functions}|${batch_insert_size}|${prepared_statements}|${loose_bbox}|${ssl_mode}|${estimated_extends}|${fetch_size}|${expose_primary_keys}|${validate_connections}|${support_geometry_simplification}|${connection_timeout}|${create_database}|${simplify_method}|${min_connections}|${max_connections}|${evictor_tests_per_run}|${test_while_idle}|${max_connection_idle_time}"
}

main() {
    echo "=== Обновление паролей хранилищ GeoServer ==="
    echo ""
    echo "Проверка подключения к GeoServer..."
    if ! curl -u "$GEOSERVER_USER:$GEOSERVER_PASS" \
         -s "$GEOSERVER_URL/rest/about/version.xml" \
         | grep -q "GeoServer"; then
        echo "ОШИБКА: Не удалось подключиться к GeoServer"
        exit 1
    fi
    echo "✓ Подключение успешно"

    find_and_update_datastores

    echo ""
    echo "=== Обновление завершено ==="
}

main "$@"
