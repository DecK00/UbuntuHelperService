#!/bin/bash

# Функция для начальной настройки
on_start() {
    echo "Загружаю переменные из .env..."
    source .env  # Загружаем переменные окружения из файла .env
    update_system  # Обновляем систему
    echo "Устанавливаю пакет apache2-utils..."
    apt-get install apache2-utils -y  # Устанавливаем пакет apache2-utils
    install_docker
    install_traefik
    timedatectl set-timezone UTC
    timedatectl set-ntp on
}

# Функция для обновления системы
update_system() {
    echo "Обновление системы..."
    apt-get update && apt-get upgrade -y  # Обновление списка пакетов и их установка
}

# Функция для установки Docker
install_docker() {
    echo "Загружаю скрипт установки Docker..."
    curl -fsSL https://get.docker.com -o get-docker.sh  # Загружаем скрипт установки Docker
    echo "Устанавливаю Docker..."
    sh get-docker.sh  # Запускаем скрипт установки
    echo "Удаляю скрипт установки Docker..."
    rm get-docker.sh  # Удаляем временный скрипт установки
    echo "Создаю сеть Docker с именем 'proxy'..."
    docker network create proxy  # Создаём Docker-сеть
}

# Функция для установки Traefik
install_traefik() {
    echo "Создаю хеш пароля для пользователя 'admin'..."
    HASH_PASSWORD_TRAEFIK=$(htpasswd -bnB "admin" "$PASSWORD_TRAEFIK" | sed -e 's/\$/\$\$/g')  # Генерация хеша пароля

    echo "Проверяю наличие директории /root/project/traefik..."
    if [ ! -d "/root/project/traefik" ]; then
        echo "Директория /root/project/traefik не найдена. Создаю директорию..."
        mkdir -p /root/project/traefik  # Создаём директорию для Traefik
    else
        echo "Директория /root/project/traefik уже существует."
    fi

    echo "Копирую файлы для Traefik..."
    cp -r /root/project/template/traefik/. /root/project/traefik

    echo "Настраиваю файл acme.json для Traefik..."
    chmod u=rw,go= /root/project/traefik/acme.json  # Устанавливаем права доступа к acme.json

    echo "Заменяю параметры в docker-compose.yml для Traefik..."
    sed -i -e "s|PASSWORD_TRAEFIK|$HASH_PASSWORD_TRAEFIK|g" /root/project/traefik/docker-compose.yml
    sed -i -e "s|URL|$URL|g" /root/project/traefik/docker-compose.yml
    sed -i -e "s|CF_EMAIL|$CF_EMAIL|g" /root/project/traefik/docker-compose.yml
    sed -i -e "s|CF_TOKEN|$CF_TOKEN|g" /root/project/traefik/docker-compose.yml
    sed -i -e "s|CF_EMAIL|$CF_EMAIL|g" /root/project/traefik/traefik.yml

    echo "Запускаю контейнер Traefik..."
    docker compose -f /root/project/traefik/docker-compose.yml up -d  # Запуск контейнеров Traefik
}

# Функция для установки Dockge
install_dockge() {
    echo "Проверяю наличие директории /root/project/dockge..."
    if [ ! -d "/root/project/dockge" ]; then
        echo "Директория /root/project/dockge не найдена. Создаю директорию..."
        mkdir -p /root/project/dockge  # Создаём директорию для Dockge
    else
        echo "Директория /root/project/dockge уже существует."
    fi

    echo "Копирую файлы для Dockge..."
    cp -r /root/project/template/dockge/. /root/project/dockge

    echo "Заменяю параметры в docker-compose.yml для Dockge..."
    sed -i -e "s|URL|$URL|g" /root/project/dockge/docker-compose.yml

    echo "Запускаю контейнер Dockge..."
    docker compose -f /root/project/dockge/docker-compose.yml up -d  # Запуск контейнеров Dockge
}

# Функция для установки Portainer
install_portainer() {
    echo "Проверяю наличие директории /root/project/portainer..."
    if [ ! -d "/root/project/portainer" ]; then
        echo "Директория /root/project/portainer не найдена. Создаю директорию..."
        mkdir -p /root/project/portainer  # Создаём директорию для Portainer
    else
        echo "Директория /root/project/portainer уже существует."
    fi

    echo "Копирую файлы для Portainer..."
    cp -r /root/project/template/portainer/. /root/project/portainer

    echo "Заменяю параметры в docker-compose.yml для Portainer..."
    sed -i -e "s|URL|$URL|g" /root/project/portainer/docker-compose.yml

    echo "Запускаю контейнер Portainer..."
    docker compose -f /root/project/portainer/docker-compose.yml up -d  # Запуск контейнеров Portainer
}

# Функция для установки Watchtower
install_watchtower() {
    echo "Проверяю наличие директории /root/project/watchtower..."
    if [ ! -d "/root/project/watchtower" ]; then
        echo "Директория /root/project/watchtower не найдена. Создаю директорию..."
        mkdir -p /root/project/watchtower  # Создаём директорию для Watchtower
    else
        echo "Директория /root/project/watchtower уже существует."
    fi

    echo "Копирую файлы для Watchtower..."
    cp -r /root/project/template/watchtower/. /root/project/watchtower

    echo "Заменяю параметры в docker-compose.yml для Watchtower..."
    sed -i -e "s|TG_BOT_TOKEN|$TG_BOT_TOKEN|g" /root/project/watchtower/docker-compose.yml
    sed -i -e "s|TG_CHANNEL_WATCHTOWER|$TG_CHANNEL_WATCHTOWER|g" /root/project/watchtower/docker-compose.yml

    echo "Запускаю контейнер Watchtower..."
    docker compose -f /root/project/watchtower/docker-compose.yml up -d  # Запуск контейнеров Watchtower
}

# Функция для установки мониторинга (Grafana, Prometheus и др.)
install_monitoring() {
    install_grafana  # Установка Grafana
    install_prometheus  # Установка Prometheus
    install_nodeexporter  # Установка Node Exporter
    install_cadvisor  # Установка Cadvisor
    install_pushgateway  # Установка Pushgateway
}

# Функция для установки 3x-ui
install_3x_ui() {
    echo "Проверяю наличие директории /root/project/3x-ui..."
    if [ ! -d "/root/project/3x-ui" ]; then
        echo "Директория /root/project/3x-ui не найдена. Клонирую репозиторий..."
        git clone https://github.com/MHSanaei/3x-ui  # Клонирование репозитория 3x-ui
    else
        echo "Директория /root/project/3x-ui уже существует."
    fi

    echo "Копирую файлы для 3x-ui..."
    cp -r /root/project/template/3x-ui/. /root/project/3x-ui

    echo "Заменяю параметры в docker-compose.yml для 3x-ui..."
    sed -i -e "s|URL|$URL|g" /root/project/3x-ui/docker-compose.yml
    sed -i -e "s|HOST_SNI|$HOST_SNI|g" /root/project/3x-ui/docker-compose.yml

    echo "Запускаю контейнер 3x-ui..."
    docker compose -f /root/project/3x-ui/docker-compose.yml up -d  # Запуск контейнеров 3x-ui
}

# Функция для установки Grafana
install_grafana() {
    echo "Проверяю наличие директории /root/project/grafana..."
    if [ ! -d "/root/project/grafana" ]; then
        echo "Директория /root/project/grafana не найдена. Создаю директорию..."
        mkdir -p /root/project/grafana  # Создаём директорию для Grafana
    else
        echo "Директория /root/project/grafana уже существует."
    fi

    echo "Копирую файлы для Grafana..."
    cp -r /root/project/template/grafana/. /root/project/grafana

    echo "Заменяю параметры в docker-compose.yml для Grafana..."
    sed -i -e "s|URL|$URL|g" /root/project/grafana/docker-compose.yml
    sed -i -e "s|USER_GRAFANA|$USER_GRAFANA|g" /root/project/grafana/docker-compose.yml
    sed -i -e "s|PASSWORD_GRAFANA|$PASSWORD_GRAFANA|g" /root/project/grafana/docker-compose.yml

    echo "Запускаю контейнер Grafana..."
    docker compose -f /root/project/grafana/docker-compose.yml up -d  # Запуск контейнеров Grafana
}

# Функция для установки Prometheus
install_prometheus() {
    echo "Создаю хеш пароля для пользователя 'admin'..."
    HASH_PASSWORD_PROMETHEUS=$(htpasswd -bnB "admin" "$PASSWORD_PROMETHEUS" | sed -e 's/\$/\$\$/g')

    echo "Проверяю наличие директории /root/project/prometheus..."
    if [ ! -d "/root/project/prometheus" ]; then
        echo "Директория /root/project/prometheus не найдена. Создаю директорию..."
        mkdir -p /root/project/prometheus  # Создаём директорию для Prometheus
    else
        echo "Директория /root/project/prometheus уже существует."
    fi

    echo "Копирую файлы для Prometheus..."
    cp -r /root/project/template/prometheus/. /root/project/prometheus

    echo "Заменяю параметры в docker-compose.yml для Prometheus..."
    sed -i -e "s|PASSWORD_PROMETHEUS|$HASH_PASSWORD_PROMETHEUS|g" /root/project/prometheus/docker-compose.yml
    sed -i -e "s|URL|$URL|g" /root/project/prometheus/docker-compose.yml

    echo "Запускаю контейнер Prometheus..."
    docker compose -f /root/project/prometheus/docker-compose.yml up -d  # Запуск контейнеров Prometheus
}

# Функция для установки Node Exporter
install_nodeexporter() {
    echo "Проверяю наличие директории /root/project/nodeexporter..."
    if [ ! -d "/root/project/nodeexporter" ]; then
        echo "Директория /root/project/nodeexporter не найдена. Создаю директорию..."
        mkdir -p /root/project/nodeexporter  # Создаём директорию для Node Exporter
    else
        echo "Директория /root/project/nodeexporter уже существует."
    fi

    echo "Копирую файлы для Nodeexporter..."
    cp -r /root/project/template/nodeexporter/. /root/project/nodeexporter

    echo "Запускаю контейнер Nodeexporter..."
    docker compose -f /root/project/nodeexporter/docker-compose.yml up -d  # Запуск контейнеров Node Exporter
}

# Функция для установки Cadvisor
install_cadvisor() {
    echo "Проверяю наличие директории /root/project/cadvisor..."
    if [ ! -d "/root/project/cadvisor" ]; then
        echo "Директория /root/project/cadvisor не найдена. Создаю директорию..."
        mkdir -p /root/project/cadvisor  # Создаём директорию для Cadvisor
    else
        echo "Директория /root/project/cadvisor уже существует."
    fi

    echo "Копирую файлы для Cadvisor..."
    cp -r /root/project/template/cadvisor/. /root/project/cadvisor

    echo "Запускаю контейнер Cadvisor..."
    docker compose -f /root/project/cadvisor/docker-compose.yml up -d  # Запуск контейнеров Cadvisor
}

# Функция для установки Pushgateway
install_pushgateway() {
    echo "Проверяю наличие директории /root/project/pushgateway..."
    if [ ! -d "/root/project/pushgateway" ]; then
        echo "Директория /root/project/pushgateway не найдена. Создаю директорию..."
        mkdir -p /root/project/pushgateway
    else
        echo "Директория /root/project/pushgateway уже существует."
    fi

    echo "Копирую файлы для Pushgateway..."
    cp -r /root/project/template/pushgateway/. /root/project/pushgateway

    echo "Запускаю контейнер Pushgateway..."
    docker compose -f /root/project/pushgateway/docker-compose.yml up -d  # Запуск контейнеров Pushgateway
}


if [ -z "$BASH_VERSION" ]; then
    echo "Скрипт запущен из sh или другой оболочки."
    echo "Пожалуйста, запустите его через bash: 'bash main.sh'"
else
    declare -A functions
    functions=(
        ["Установка_Dockge"]="install_dockge"
        ["Установка_Portainer"]="install_portainer"
        ["Установка_Watchtower"]="install_watchtower"
        ["Установка_Monitoring"]="install_monitoring"
        ["Установка_3x-ui"]="install_3x_ui"
    )
    options=()
    for func_name in "${!functions[@]}"; do
        options+=("$func_name" "" OFF)
    done
    selected_functions=$(whiptail --title "Выбор задач" --checklist \
        "Выберите задачи для выполнения:" 20 78 10 "${options[@]}" 3>&1 1>&2 2>&3)
    if [ $? -eq 0 ]; then
        if [ -z "$selected_functions" ]; then
            echo "Ничего не выбрано."
        else
            on_start
            for func_name in $selected_functions; do
                func_name=$(echo "$func_name" | tr -d '"')
                if [[ -n "${functions[$func_name]}" ]]; then
                    func_to_call=${functions[$func_name]}
                    $func_to_call
                else
                    echo "Ошибка: функция $func_name не найдена."
                fi
            done
        fi
    else
        echo "Отмена выбора."
    fi
fi