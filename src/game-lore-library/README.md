# Game Lore Library

Этот модуль содержит библиотеку статей лора и механик игры в формате Markdown. Статьи организованы по оглавлению `toc.json` и разделены на два окружения (<env>): `stage/` и `production/`.

- Директория статей: `src/game-lore-library/<env>/articles/`
- Оглавление: `src/game-lore-library/<env>/toc.json`
- Конвертация изображений: `convert_to_avif.sh`
- Валидация оглавления и файлов: `validate_toc.sh`

Для начала работы перейдите к разделу [«Быстрый старт»](docs/quickstart.md).

## Ожидаемое поведение

- Фронтенд импортирует `toc.json`, загружает статьи и изображения через raw-ссылки.
- Каждая статья отображается с заголовком и контентом.
- Картинки для каждой статьи доступны из папки `images` внутри директории статьи.

## Документация

- [Подготовка](docs/prepare.md)
- [Быстрый старт](docs/quickstart.md)
- [Структура проекта](docs/structure.md)
- [Формат toc.json](docs/toc_format.md)
- [Изображения и AVIF](docs/images.md)
- [Валидация toc.json](docs/validation.md)
- [Ссылки и якоря в статьях](docs/links.md)
- [Нормализация названий статей (snake_case)](docs/normalization.md)

## Утилиты (Docker-меню)

Для удобного запуска служебных скриптов используйте меню:

```bash
cd src/game-lore-library
chmod +x ma-tools.sh
./ma-tools.sh
```

### Windows

- __Установка Git Bash__
  - Скачайте и установите «Git for Windows»: https://git-scm.com/downloads/win
  - Во время установки оставьте включёнными опции «Git Bash» и «Git Bash Here» (контекстное меню Проводника).
  - После установки откройте «Git Bash» через меню Пуск или правым кликом по папке → «Git Bash Here».

- __Git Bash (рекомендуется)__
  - Откройте Git Bash в корне репозитория и выполните команды выше без изменений.

- __WSL__
  - Убедитесь, что репозиторий доступен в `/mnt/c/...`
  - Пример:
    ```bash
    cd /mnt/c/Users/<user>/WebstormProjects/MA-static-content/src/game-lore-library
    chmod +x ma-tools.sh
    ./ma-tools.sh
    ```

- __PowerShell/CMD__
  - Непосредственно не подходят: `ma-tools.sh` — bash-скрипт. Используйте Git Bash или WSL.

Доступные пункты:

- Нормализация названий (snake_case)
- Валидация toc.json
- Конвертация изображений в AVIF

Каждый пункт автоматически соберёт/переиспользует нужный Docker-образ и выполнит команду с корректным монтированием каталогов.
