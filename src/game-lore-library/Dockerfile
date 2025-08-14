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

# Нормализация окончаний строк (CRLF -> LF) и права на выполнение
# На Windows репозиторий может иметь CRLF, что ломает шебанг. Удаляем '\r'.
RUN sed -i 's/\r$//' /app/convert_to_avif.sh && chmod +x /app/convert_to_avif.sh

# Точка входа - явный запуск через bash (надёжнее при различиях окружений)
ENTRYPOINT ["/bin/bash", "/app/convert_to_avif.sh"]
