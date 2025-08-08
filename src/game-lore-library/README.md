# Game Lore Library

## Описание

Данный подпроект хранит статьи по лору игры и механикам в виде markdown-файлов, связанных через файл оглавления.

## Быстрый старт: добавление новой статьи

Эта инструкция описывает, как добавить новую статью в базу знаний игры.

### 1. Создайте папку для новой статьи

В директории `src/game-lore-library/stage/articles/` создайте новую папку с названием вашей статьи (без пробелов,
используйте нижние подчеркивания).

Пример: `src/game-lore-library/stage/articles/dragons_of_the_north/`

### 2. Добавьте файлы статьи

В созданной папке создайте файлы статей с расширением `.md`:

- Основной файл на русском языке: `dragons_of_the_north_ru.md`
- Если нужна английская версия: `dragons_of_the_north_en.md`

### 3. Добавьте изображения

Если в статье есть изображения:

1. Создайте папку `images` внутри папки статьи
2. Поместите изображения в эту папку в формате `.2x.png` или `.2x.jpg`
3. Пример пути: `dragons_of_the_north/images/dragon-fire.2x.png`

### 4. Конвертируйте изображения в AVIF

После добавления всех изображений запустите инструмент конвертации, чтобы создать AVIF-версии (подробная инструкция ниже
в разделе "Конвертация изображений").

### 5. Добавьте статью в оглавление

Откройте файл `src/game-lore-library/stage/toc.json` и добавьте вашу статью в соответствующий раздел (WIKI или LORE)
согласно формату описанному в разделе "Формат toc.json"

## Структура

src/game-lore-library/
├── stage/
│ ├── toc.json # оглавление статей
│ └── articles/ # markdown-статьи
│ ├── [Название_статьи]/ # отдельная директория для каждой статьи
│ │ ├── [Название_статьи]*ru.md # файл статьи на русском
│ │ ├── [Название*статьи]\_en.md # файл статьи на английском (опционально)
│ │ └── images/ # изображения для конкретной статьи
└── production/
├── toc.json
└── articles/

## Формат toc.json

Файл `toc.json` поддерживает мультиязычные статьи и категории, разделенные на две основные секции: WIKI и LORE.

### 1. Структура файла

Файл представляет собой JSON-объект с двумя ключами "WIKI" и "LORE", значениями которых являются массивы статей и
категорий.

```json
{
  "WIKI": [
    ...
  ],
  "LORE": [
    ...
  ]
}
```

### 2. Категория со статьями

```json
{
  "title": {
    "ru": "Название категории на русском",
    "en": "Category title in English"
  },
  "items": [
    {
      "title": {
        "ru": "Название статьи на русском",
        "en": "Article title in English"
      },
      "files": {
        "ru": "articles/Название_статьи/Название_статьи_ru.md",
        "en": "articles/Название_статьи/Название_статьи_en.md"
      }
    }
  ]
}
```

### Пример полной структуры

```json
{
  "WIKI": [
    {
      "title": {
        "ru": "Механики",
        "en": "Game Mechanics"
      },
      "items": [
        {
          "title": {
            "ru": "Боевая система",
            "en": "Combat System"
          },
          "files": {
            "ru": "articles/Combat_System/Combat_System_ru.md",
            "en": "articles/Combat_System/Combat_System_en.md"
          }
        },
        {
          "title": {
            "ru": "Ребаланс Magic Towers",
            "en": "Magic Towers Rebalance"
          },
          "files": {
            "ru": "articles/Ребаланс_Magic_Towers/Ребаланс_Magic_Towers_ru.md",
            "en": "articles/Ребаланс_Magic_Towers/Ребаланс_Magic_Towers_en.md"
          }
        }
      ]
    }
  ],
  "LORE": [
    {
      "title": {
        "ru": "Мир игры",
        "en": "Game World"
      },
      "items": [
        {
          "title": {
            "ru": "О существах магических",
            "en": "About Magical Creatures"
          },
          "files": {
            "ru": "articles/О_существах_магических/О_существах_магических_ru.md",
            "en": "articles/О_существах_магических/О_существах_магических_en.md"
          }
        },
        {
          "title": {
            "ru": "Страны мира ДжиДа",
            "en": "JiDa World Countries"
          },
          "files": {
            "ru": "articles/Страны_мира_ДжиДа._Часть_4/Страны_мира_ДжиДа._Часть_4_ru.md",
            "en": "articles/Страны_мира_ДжиДа._Часть_4/Страны_мира_ДжиДа._Часть_4_en.md"
          }
        }
      ]
    }
  ]
}
```

## Ожидаемое поведение

- Фронтенд импортирует `toc.json`, загружает статьи и изображения через raw-ссылки.
- Каждая статья отображается с заголовком и контентом.
- Картинки для каждой статьи доступны из папки `images` внутри директории статьи.

## Форматы и требования к изображениям

Для статей используются изображения в следующих форматах:

- Изображения должны иметь формат `.2x.png`, `.2x.jpg`, `.2x.jpeg` или `.2x.avif`
- Каждое изображение хранится в директории `images/` внутри директории статьи
- Основной формат изображений для веб-страниц - AVIF, с PNG/JPG в качестве fallback

## Работа со скриптами

### Конвертация изображений в AVIF

Для конвертации изображений в формат AVIF используется скрипт `convert_to_avif.sh`. Доступно два варианта использования:

#### Вариант 1: Использование Docker (рекомендуется)

Этот вариант позволяет запустить конвертацию без установки зависимостей на ваш компьютер и работает на любой
операционной системе с установленным Docker.

1. Убедитесь, что у вас установлен Docker:

    - [Установка Docker](https://docs.docker.com/get-docker/)

2. Перейдите в директорию проекта и соберите имидж:

   ```bash
   cd src/game-lore-library
   docker build -t avif-converter .
   ```

3. Запустите контейнер для нужного окружения:

   ```bash
   # Для обработки изображений в окружении stage
   docker run --rm -v "$(pwd)/stage:/app/stage" avif-converter --environment stage
   ```

   ```bash
   # Для обработки изображений в окружении production
   docker run --rm -v "$(pwd)/production:/app/production" avif-converter --environment production
   ```

   Примечания:
    - `--rm` удаляет контейнер после завершения работы
    - `-v` монтирует локальную директорию статей в контейнер

#### Вариант 2: Локальный запуск

Если вы предпочитаете запустить скрипт напрямую без использования Docker:

1. Убедитесь, что у вас установлены необходимые зависимости (ImageMagick и libavif):

   Для macOS:

   ```bash
   brew install imagemagick libavif
   ```

   Для Ubuntu/Debian:

   ```bash
   sudo apt-get install imagemagick libavif-bin
   ```

   Для Windows:

    - Установите ImageMagick с официального сайта: https://imagemagick.org/script/download.php
    - Для libavif можно использовать WSL или скомпилировать из исходников: https://github.com/AOMediaCodec/libavif

2. Запустите скрипт для нужного окружения:

```bash
# Перейдите в директорию проекта если вы находитесь в другом каталоге
   cd src/game-lore-library
```

```bash
   chmod +x convert_to_avif.sh
```

```bash
# Для обработки изображений в окружении stage (по умолчанию)
./convert_to_avif.sh
```

### Что делает конвертер

Конвертер автоматически:

- Находит все картинки `.2x.png`, `.2x.jpg` или `.2x.jpeg` в папках статей
- Создаёт несколько версий каждого изображения в формате AVIF:
    - `.2x.avif` - полноразмерная версия
    - `.1x.avif` - уменьшенная в два раза версия
    - `.mobile.2x.avif` - версия для мобильных устройств (55% от оригинала)
    - `.mobile.1x.avif` - уменьшенная версия для мобильных устройств
- Сохраняет новые файлы рядом с оригиналами в той же папке
- Не трогает оригинальные файлы
- Пропускает уже созданные AVIF файлы (если нужно пересоздать их, сначала удалите старые файлы вручную)

### Валидация файлов toc.json

Скрипт `validate_toc.sh` проверяет корректность файлов `toc.json` и наличие всех указанных в нем файлов статей. Он
выполняет следующие проверки:

- Валидность JSON-структуры
- Наличие обязательных разделов (WIKI и LORE)
- Корректность структуры категорий и статей
- Физическое наличие всех указанных MD-файлов статей
- Правильность формата путей к файлам

#### Валидация через Docker

Для запуска валидации на любой операционной системе через Docker:

```bash
# Перейти в директорию проекта
cd src/game-lore-library
 ```

   ```bash
# Собрать образ валидатора
docker build -t toc-validator -f Dockerfile.validator .
 ```

   ```bash
# Проверить оба окружения (stage и production)
docker run --rm -v "$(pwd):/app" toc-validator
 ```

   ```bash
# ИЛИ проверить только stage
docker run --rm -v "$(pwd):/app" toc-validator -e stage
 ```

   ```bash
# ИЛИ проверить только production
docker run --rm -v "$(pwd):/app" toc-validator -e production
 ```

   ```bash
# ИЛИ с подробным выводом
docker run --rm -v "$(pwd):/app" toc-validator -v
```

### Как запустить конвертацию изображений

#### Самый простой способ (для Windows, Mac, Linux)

1. Установите Docker Desktop на ваш компьютер:
    - Скачайте и установите с сайта [Docker](https://www.docker.com/products/docker-desktop/)
    - Запустите Docker Desktop после установки

2. Откройте терминал или командную строку

3. Перейдите в директорию game-lore-library:
   ```bash
   cd путь/до/проекта/src/game-lore-library
   ```

4. Выполните одну команду для конвертации всех изображений:
   ```bash
   docker build -t avif-converter . && docker run --rm -v "$(pwd)/stage:/app/stage" avif-converter --environment stage
   ```

5. Дождитесь завершения конвертации (это может занять несколько минут)

6. Готово! Все необходимые AVIF-версии изображений были созданы

Если у вас возникли проблемы, обратитесь к разработчикам для получения помощи.

## Работа с файлами

1. Клонировать репозиторий:

```bash
git clone https://github.com/magicalchemy/static-content.git
cd static-content
```

git clone https://github.com/magicalchemy/static-content.git
cd static-content

   ```

2. Обновить статьи в `src/game-lore-library/stage/articles` и изображения в директориях `images/` внутри каждой статьи.

3. Обновить `src/game-lore-library/stage/toc.json`.

4. При необходимости, конвертировать изображения в AVIF используя скрипт `convert_to_avif.sh`.

5. Закоммитить изменения:

   ```bash
   git commit -m "update game lore articles"
   ```

6. Залить изменения на GitHub:

   ```bash
   git push origin main
   ```

7. Протестировать на stage через raw-ссылку:

   ```
   https://raw.githubusercontent.com/magicalchemy/static-content/refs/heads/main/src/game-lore-library/stage/toc.json
   ```

   и на сайте https://stage.magicalchemy.org/world/library

8. Если все хорошо, скопировать содержимое из `stage/` в `production/`:

    - Скопировать статьи из `stage/articles/` в `production/articles/`
    - Скопировать `stage/toc.json` в `production/toc.json`

9. Закоммитить изменения:

   ```bash
   git commit -m "update game lore articles in production"
   ```

10. Залить изменения на GitHub:

    ```bash
    git push origin main
    ```

11. Протестировать на production через raw-ссылку:
    ```
    https://raw.githubusercontent.com/magicalchemy/static-content/refs/heads/main/src/game-lore-library/production/toc.json
    ```
    и на сайте https://magicalchemy.org/world/library
