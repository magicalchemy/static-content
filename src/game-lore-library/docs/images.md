# Изображения и конвертация в AVIF

[← Назад к README](../README.md)

## Форматы

- Исходные: `.2x.png`, `.2x.jpg`, `.2x.jpeg`
- Целевые: `.2x.avif`, `.1x.avif`, `.mobile.2x.avif`, `.mobile.1x.avif`
- Хранить в `images/` внутри папки статьи.

## Конвертация (Docker — рекомендуется)

### Быстрый запуск (через меню утилит)

Рекомендуется использовать общее меню утилит — оно само соберёт образ и смонтирует каталоги корректно:

```bash
chmod +x ma-tools.sh
./ma-tools.sh
```

Далее выберите пункт «Конвертация изображений в AVIF» и укажите окружение (stage/production).

### Вручную через Docker

Общий порядок действий (любой ОС):

```bash
cd src/game-lore-library
docker build -t avif-converter .
```

Далее запуск контейнера отличается в зависимости от оболочки:

- macOS/Linux bash/zsh (или WSL):

  ```bash
  # Самый надёжный способ — смонтировать всю папку в /app
  docker run --rm -it -v "$(pwd):/app" avif-converter -e stage
  # production
  # docker run --rm -it -v "$(pwd):/app" avif-converter -e production
  ```

- Windows PowerShell:

  ```powershell
  docker run --rm -it -v "${PWD}:/app" avif-converter -e stage
  # production
  # docker run --rm -it -v "${PWD}:/app" avif-converter -e production
  ```

- Windows CMD:
  ```cmd
  docker run --rm -it -v "%cd%:/app" avif-converter -e stage
  rem production
  rem docker run --rm -it -v "%cd%:/app" avif-converter -e production
  ```

Примечание: мы монтируем всю директорию `src/game-lore-library` в `/app`, т.к. внутри образа точка входа — `/app/convert_to_avif.sh`, который сам ищет статьи по пути `/app/<env>/articles`. Монтирование только подкаталога `stage`/`production` допустимо, но требует точного синтаксиса путей в вашей оболочке.

Примечание: если вы уже собирали образ через меню (`ma-tools.sh`), он имеет тег `ma-gl-avif`. Можно использовать его вместо `avif-converter`:

```bash
# bash/zsh/WSL
docker run --rm -it -v "$(pwd):/app" ma-gl-avif -e stage
# PowerShell
docker run --rm -it -v "${PWD}:/app" ma-gl-avif -e stage
# CMD
docker run --rm -it -v "%cd%:/app" ma-gl-avif -e stage
```

## Конвертация локально

macOS:

```bash
brew install imagemagick libavif
cd src/game-lore-library
chmod +x convert_to_avif.sh
./convert_to_avif.sh
```

Скрипт автоматически создаёт версии AVIF, не изменяет оригиналы и пропускает уже существующие `.avif` файлы.

## Что делает конвертер

Конвертер автоматически:

- Находит все картинки `.2x.png`, `.2x.jpg` или `.2x.jpeg` в папках статей
- Создаёт несколько версий каждого изображения в формате AVIF:
  - `.2x.avif` — полноразмерная версия
  - `.1x.avif` — уменьшенная в два раза версия
  - `.mobile.2x.avif` — версия для мобильных устройств (≈55% от оригинала)
  - `.mobile.1x.avif` — уменьшенная версия для мобильных устройств
- Сохраняет новые файлы рядом с оригиналами в той же папке
- Не трогает оригинальные файлы
- Пропускает уже созданные AVIF файлы (для пересоздания удалите старые файлы вручную)

## Как запустить конвертацию изображений

### Самый простой способ (Windows, macOS, Linux)

1. Установите Docker Desktop и запустите его
2. Откройте терминал и перейдите в `src/game-lore-library`
3. Выполните одну команду для stage (выберите синтаксис под вашу оболочку):

```bash
# bash/zsh/WSL
docker build -t avif-converter . && docker run --rm -it -v "$(pwd):/app" avif-converter -e stage

# PowerShell
docker build -t avif-converter . ; docker run --rm -it -v "${PWD}:/app" avif-converter -e stage

# CMD
docker build -t avif-converter . && docker run --rm -it -v "%cd%:/app" avif-converter -e stage
```

Готово — все необходимые AVIF-версии изображений будут созданы.
