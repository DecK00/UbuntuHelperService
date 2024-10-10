#!/bin/sh

# Проверка, запущен ли скрипт из bash
if [ -z "$BASH_VERSION" ]; then
    echo "Скрипт запущен из sh или другой оболочки."
    echo "Пожалуйста, запустите его через bash: 'bash main.sh'"
else
    echo "Скрипт запущен из bash."

    # Загрузка переменных из .env
    echo "Загружаю переменные из .env..."
    source .env

    echo "Обновляю список пакетов..."
    apt-get update
    echo "Обновляю установленные пакеты..."
    apt-get upgrade -y
    echo "Устанавливаю пакет apache2-utils..."
    apt-get install apache2-utils -y

    echo "Загружаю скрипт установки Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh
    echo "Устанавливаю Docker..."
    sh get-docker.sh
    echo "Удаляю скрипт установки Docker..."
    rm get-docker.sh
    echo "Создаю сеть Docker с именем 'proxy'..."
    docker network create proxy

    if [ ! -d "/root/project/3x-ui" ]; then
        echo "Директория /root/3x-ui не существует. Клонирую репозиторий..."
        git clone https://github.com/MHSanaei/3x-ui
    else
        echo "Директория /root/project/3x-ui уже существует."
    fi

    # Создание хеша пароля
    echo "Создаю хеш пароля для пользователя 'admin'..."
    HASH_PASSWORD=$(htpasswd -bnB "admin" "$PASSWORD" | sed -e 's/\$/\$\$/g')

    echo "Настраиваю файл acme.json..."
    chmod u=rw,go= /root/project/traefik/acme.json
    echo "Копирую файл docker-compose.yml для Traefik..."
    cp /root/project/traefik_docker-compose.yml /root/project/traefik/docker-compose.yml
    echo "Заменяю параметры в файле docker-compose.yml для Traefik..."
    sed -i -e "s|PASS|$HASH_PASSWORD|g" /root/project/traefik/docker-compose.yml
    sed -i -e "s|URL|$URL|g" /root/project/traefik/docker-compose.yml
    sed -i -e "s|CF_EMAIL|$CF_EMAIL|g" /root/project/traefik/docker-compose.yml
    sed -i -e "s|CF_TOKEN|$CF_TOKEN|g" /root/project/traefik/docker-compose.yml

    echo "Запускаю контейнеры Traefik..."
    docker compose -f /root/project/traefik/docker-compose.yml up -d

    echo "Копирую файл docker-compose.yml для Portainer..."
    cp /root/project/portainer_docker-compose.yml /root/project/portainer/docker-compose.yml
    echo "Заменяю параметры в файле docker-compose.yml для Portainer..."
    sed -i -e "s|URL|$URL|g" /root/project/portainer/docker-compose.yml
    echo "Запускаю контейнеры Portainer..."
    docker compose -f /root/project/portainer/docker-compose.yml up -d

    echo "Копирую файл docker-compose.yml для 3x-ui..."
    cp /root/project/3x-ui_docker-compose.yml /root/project/3x-ui/docker-compose.yml
    echo "Заменяю параметры в файле docker-compose.yml для 3x-ui..."
    sed -i -e "s|URL|$URL|g" /root/project/3x-ui/docker-compose.yml
    sed -i -e "s|HOST_SNI|$HOST_SNI|g" /root/project/3x-ui/docker-compose.yml
    echo "Запускаю контейнеры 3x-ui..."
    docker compose -f /root/project/3x-ui/docker-compose.yml up -d
fi