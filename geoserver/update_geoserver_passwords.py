#!/usr/bin/env python3

import os
import sys
import requests
import xml.etree.ElementTree as ET
import glob
import re
import logging
from urllib.parse import quote
from typing import Dict, Optional

# Настройка логирования
logging.basicConfig(level=logging.INFO, format='%(message)s')
logger = logging.getLogger(__name__)

# Переменные окружения
GEOSERVER_URL = os.getenv("GEOSERVER_URL", "http://localhost:8080/geoserver")
GEOSERVER_WORKSPACES_DIR = os.getenv("GEOSERVER_WORKSPACES_DIR", "/data/geoserver/data_dir/workspaces")
GEOSERVER_USER = os.getenv("GEOSERVER_USER", "admin")
GEOSERVER_PASS = os.getenv("GEOSERVER_PASS", "admin123")

# Словарь паролей по базам данных
PASSWORDS = {
    "bgd_1": "bgd_1_password",
    "bgd_2": "bgd_2_password",
    "bgd_3": "bgd_3_password",
}

# Функция для извлечения значения из XML по ключу
def extract_xml_value(xml_file: str, key: str) -> Optional[str]:
    try:
        tree = ET.parse(xml_file)
        root = tree.getroot()
        for entry in root.findall(".//entry[@key='{}']".format(key)):
            return entry.text
    except Exception as e:
        logger.error(f"Ошибка при парсинге XML {xml_file}: {e}")
    return None

# Функция для чтения datastore.xml и извлечения базы данных
def parse_datastore_xml(xml_file: str) -> Optional[str]:
    if not os.path.isfile(xml_file):
        logger.error(f"Файл {xml_file} не найден")
        return None
    return extract_xml_value(xml_file, "database")

# Функция для обновления пароля в хранилище
def update_datastore(workspace: str, datastore: str, xml_file: str):
    logger.info(f"Обновление хранилища: {datastore}")
    
    # Проверка существования файла
    if not os.path.isfile(xml_file):
        logger.error(f"  Ошибка: файл конфигурации {xml_file} не найден")
        return False

    # Извлекаем имя базы данных
    database = parse_datastore_xml(xml_file)
    if not database:
        logger.error(f"  Ошибка: не удалось прочитать базу данных из XML")
        return False

    # Получаем пароль из словаря
    password = PASSWORDS.get(database)
    if not password:
        logger.warning(f"  Пароль для базы данных {database} хранилища {datastore} не задан, обновление пропускается")
        return True  # Продолжаем, но не обновляем

    # Получаем текущую конфигурацию
    url = f"{GEOSERVER_URL}/rest/workspaces/{workspace}/datastores/{datastore}"
    try:
        response = requests.get(url, auth=(GEOSERVER_USER, GEOSERVER_PASS), headers={"Accept": "application/json"})
        if response.status_code != 200:
            logger.error(f"  Ошибка при получении конфигурации: {response.status_code} - {response.text}")
            return False
    except Exception as e:
        logger.error(f"  Ошибка при запросе к GeoServer: {e}")
        return False

    # Декодируем JSON
    try:
        data = response.json()
    except Exception as e:
        logger.error(f"  Ошибка при декодировании JSON: {e}")
        return False

    # Обновляем пароль (в JSON-конфиге)
    # Убедимся, что есть поле с паролем
    if "datastore" in data and "connectionParameters" in data["datastore"]:
        conn_params = data["datastore"]["connectionParameters"]
        if "password" in conn_params:
            conn_params["password"] = password
        else:
            logger.warning(f"  Поле password не найдено в connectionParameters, добавляем")
            conn_params["password"] = password
    else:
        logger.error(f"  Не найдено поле connectionParameters в конфигурации")
        return False

    # Отправляем обновление
    try:
        response = requests.put(
            url,
            json=data,
            auth=(GEOSERVER_USER, GEOSERVER_PASS),
            headers={"Content-Type": "application/json", "Accept": "application/json"}
        )
        if response.status_code == 200:
            logger.info(f"  ✓ Успешно обновлено")
            if response.text:
                logger.info(f"  Ответ сервера: {response.text}")
            return True
        else:
            logger.error(f"  Ошибка HTTP {response.status_code}")
            logger.error(f"  Ответ сервера: {response.text}")
            logger.error(f"  Тело запроса: {data}")
            return False
    except Exception as e:
        logger.error(f"  Ошибка при отправке запроса: {e}")
        return False

# Функция поиска и обновления всех datastore.xml
def find_and_update_datastores():
    logger.info("Поиск хранилищ для обновления...")
    xml_files = glob.glob(f"{GEOSERVER_WORKSPACES_DIR}/**/datastore.xml", recursive=True)
    if not xml_files:
        logger.warning("  Не найдено ни одного datastore.xml")
        return

    for xml_file in xml_files:
        # Определяем workspace и datastore
        workspace_dir = os.path.dirname(os.path.dirname(xml_file))
        workspace = os.path.basename(workspace_dir)
        datastore = os.path.basename(os.path.dirname(xml_file))

        update_datastore(workspace, datastore, xml_file)

# Главная функция
def main():
    print("=== Обновление паролей хранилищ GeoServer ===")
    print("")

    # Проверка подключения к GeoServer
    logger.info("Проверка подключения к GeoServer...")
    try:
        response = requests.get(
            f"{GEOSERVER_URL}/rest/about/version.xml",
            auth=(GEOSERVER_USER, GEOSERVER_PASS),
            headers={"Accept": "application/xml"}
        )
        if response.status_code != 200 or "GeoServer" not in response.text:
            logger.error("ОШИБКА: Не удалось подключиться к GeoServer")
            sys.exit(1)
    except Exception as e:
        logger.error(f"ОШИБКА: Не удалось подключиться к GeoServer: {e}")
        sys.exit(1)

    logger.info("✓ Подключение успешно")
    find_and_update_datastores()
    print("")
    print("=== Обновление завершено ===")

if __name__ == "__main__":
    main()