FROM ubuntu:22.04

# Установка необходимых пакетов без запроса подтверждения
ENV DEBIAN_FRONTEND=noninteractive

# Обновление репозиториев и установка необходимых зависимостей
RUN apt-get update && apt-get install -y \
    imagemagick \
    libavif-bin \
    bc \
    findutils \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Создание рабочей директории
WORKDIR /app

# Копирование скрипта конвертации в контейнер
COPY convert_to_avif.sh /app/

# Предоставление прав на выполнение скрипта
RUN chmod +x /app/convert_to_avif.sh

# Точка входа - наш скрипт
ENTRYPOINT ["/app/convert_to_avif.sh"]
