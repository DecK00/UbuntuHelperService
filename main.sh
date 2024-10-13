#!/bin/sh

# Проверка, запущен ли скрипт из bash
if [ -z "$BASH_VERSION" ]; then
    echo "Скрипт запущен из sh или другой оболочки."
    echo "Пожалуйста, запустите его через bash: 'bash main.sh'"
else
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

    # ------------------------------Установка Traefik
    echo "Создаю хеш пароля для пользователя 'admin'..."
    HASH_PASSWORD_TRAEFIK=$(htpasswd -bnB "admin" "$PASSWORD_TRAEFIK" | sed -e 's/\$/\$\$/g')

    echo "Проверяю наличие директории /root/project/traefik..."
    if [ ! -d "/root/project/traefik" ]; then
        echo "Директория /root/project/traefik не найдена. Создаю директорию..."
        mkdir -p /root/project/traefik
    else
        echo "Директория /root/project/traefik уже существует."
    fi

    echo "Копирую файлы конфигурации Traefik..."
    cp /root/project/template/traefik/acme.json /root/project/traefik/acme.json
    cp /root/project/template/traefik/config.yml /root/project/traefik/config.yml
    cp /root/project/template/traefik/docker-compose.yml /root/project/traefik/docker-compose.yml
    cp /root/project/template/traefik/traefik.yml /root/project/traefik/traefik.yml

    echo "Настраиваю файл acme.json для Traefik..."
    chmod u=rw,go= /root/project/traefik/acme.json

    echo "Заменяю параметры в docker-compose.yml для Traefik..."
    sed -i -e "s|PASSWORD_TRAEFIK|$HASH_PASSWORD_TRAEFIK|g" /root/project/traefik/docker-compose.yml
    sed -i -e "s|URL|$URL|g" /root/project/traefik/docker-compose.yml
    sed -i -e "s|CF_EMAIL|$CF_EMAIL|g" /root/project/traefik/docker-compose.yml
    sed -i -e "s|CF_TOKEN|$CF_TOKEN|g" /root/project/traefik/docker-compose.yml

    echo "Запускаю контейнеры Traefik..."
    docker compose -f /root/project/traefik/docker-compose.yml up -d

    # ------------------------------Установка Dockge
    echo "Проверяю наличие директории /root/project/dockge..."
    if [ ! -d "/root/project/dockge" ]; then
        echo "Директория /root/project/dockge не найдена. Создаю директорию..."
        mkdir -p /root/project/dockge
    else
        echo "Директория /root/project/dockge уже существует."
    fi

    echo "Копирую файл docker-compose.yml для Dockge..."
    cp /root/project/template/dockge/docker-compose.yml /root/project/dockge/docker-compose.yml

    echo "Заменяю параметры в docker-compose.yml для Dockge..."
    sed -i -e "s|URL|$URL|g" /root/project/dockge/docker-compose.yml

    echo "Запускаю контейнеры Dockge..."
    docker compose -f /root/project/dockge/docker-compose.yml up -d

     # ------------------------------Установка Watchtower
    echo "Проверяю наличие директории /root/project/Watchtower..."
    if [ ! -d "/root/project/watchtower" ]; then
        echo "Директория /root/project/watchtower не найдена. Создаю директорию..."
        mkdir -p /root/project/watchtower
    else
        echo "Директория /root/project/watchtower уже существует."
    fi

    echo "Копирую файл docker-compose.yml для Watchtower..."
    cp /root/project/template/watchtower/docker-compose.yml /root/project/watchtower/docker-compose.yml

    echo "Заменяю параметры в docker-compose.yml для Watchtower..."
    sed -i -e "s|TG_BOT_TOKEN|$TG_BOT_TOKEN|g" /root/project/watchtower/docker-compose.yml
    sed -i -e "s|TG_CHANNEL_WATCHTOWER|$TG_CHANNEL_WATCHTOWER|g" /root/project/watchtower/docker-compose.yml

    echo "Запускаю контейнеры Watchtower..."
    docker compose -f /root/project/watchtower/docker-compose.yml up -d

    # ------------------------------Установка Portainer
    echo "Проверяю наличие директории /root/project/portainer..."
    if [ ! -d "/root/project/portainer" ]; then
        echo "Директория /root/project/portainer не найдена. Создаю директорию..."
        mkdir -p /root/project/portainer
    else
        echo "Директория /root/project/portainer уже существует."
    fi

    echo "Копирую файл docker-compose.yml для Portainer..."
    cp /root/project/template/portainer/docker-compose.yml /root/project/portainer/docker-compose.yml

    echo "Заменяю параметры в docker-compose.yml для Portainer..."
    sed -i -e "s|URL|$URL|g" /root/project/portainer/docker-compose.yml

    echo "Запускаю контейнеры Portainer..."
    docker compose -f /root/project/portainer/docker-compose.yml up -d

    # ------------------------------Установка Portainer
    echo "Проверяю наличие директории /root/project/3x-ui..."
    if [ ! -d "/root/project/3x-ui" ]; then
        echo "Директория /root/3x-ui не найдена. Клонирую репозиторий..."
        git clone https://github.com/MHSanaei/3x-ui
    else
        echo "Директория /root/project/3x-ui уже существует."
    fi

    echo "Копирую файл docker-compose.yml для 3x-ui..."
    cp /root/project/template/3x-ui/docker-compose.yml /root/project/3x-ui/docker-compose.yml

    echo "Заменяю параметры в docker-compose.yml для 3x-ui..."
    sed -i -e "s|URL|$URL|g" /root/project/3x-ui/docker-compose.yml
    sed -i -e "s|HOST_SNI|$HOST_SNI|g" /root/project/3x-ui/docker-compose.yml

    echo "Запускаю контейнеры 3x-ui..."
    docker compose -f /root/project/3x-ui/docker-compose.yml up -d
fi
