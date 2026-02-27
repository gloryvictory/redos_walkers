#!/bin/bash
# Запускать через sudo

GEOSERVER_WORKSPACES_DIR="/geoserver/data_dir/workspaces"
TEMP_WORKSPACES_DIR="/geoserver/data_dir/workspaces_temp"
OLD_HOST="old_HOST"
# Заменить на нужный хост при переносе
NEW_HOST="New_HOST"

# Для копирования всех пространств оставить массив пустым
# Для копирования конкретных пространст указать их в следующем формате: SELECTED_WORKSPACES=("ODIN" "DEM" "DVA")
SELECTED_WORKSPACES=()

if [ $# -gt 0 ]; then
    SELECTED_WORKSPACES=("$@")
fi

if [ ! -d "$GEOSERVER_WORKSPACES_DIR" ]; then
    echo "ОШИБКА: Директория $GEOSERVER_WORKSPACES_DIR не существует!"
    exit 1
fi

if [ ! -d "$TEMP_WORKSPACES_DIR" ]; then
    mkdir -p "$TEMP_WORKSPACES_DIR"
    echo "Создана директория $TEMP_WORKSPACES_DIR"
fi

if [ ${#SELECTED_WORKSPACES[@]} -gt 0 ]; then
    for workspace in "${SELECTED_WORKSPACES[@]}"; do
        source_dir="$GEOSERVER_WORKSPACES_DIR/$workspace"
        if [ -d "$source_dir" ]; then
            cp -r "$source_dir" "$TEMP_WORKSPACES_DIR/" 2>/dev/null
        else
            echo "ПРЕДУПРЕЖДЕНИЕ: workspace '$workspace' не существует"
        fi
    done
else
    echo "Обработка всех workspace'ов из $GEOSERVER_WORKSPACES_DIR..."
    cp -r "$GEOSERVER_WORKSPACES_DIR"/* "$TEMP_WORKSPACES_DIR"/ 2>/dev/null
fi

echo "Замена $OLD_HOST на $NEW_HOST в файлах datastore.xml..."
find "$TEMP_WORKSPACES_DIR" -name "datastore.xml" -type f -print0 | xargs -0 sed -i "s/$OLD_HOST/$NEW_HOST/g"

echo "Файлы с измененными хостами успешно перенесены в $TEMP_WORKSPACES_DIR"
