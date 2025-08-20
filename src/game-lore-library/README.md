# Game Lore Library

Этот модуль содержит библиотеку статей лора и механик игры в формате Markdown. Статьи организованы по оглавлению `toc.json` и разделены на два окружения (<env>): `stage/` и `production/`.

- Директория статей: `src/game-lore-library/<env>/articles/`
- Оглавление: `src/game-lore-library/<env>/toc.json`
- Локальные инструменты (Node.js): см. раздел «Локальные команды (Node.js)» ниже

Для начала работы перейдите к разделу [«Быстрый старт»](docs/quickstart.md).

## Ожидаемое поведение

- Фронтенд импортирует `toc.json`, загружает статьи и изображения через raw-ссылки.
- Каждая статья отображается с заголовком и контентом.
- Картинки для каждой статьи доступны из папки `images` внутри директории статьи.
 - Оглавление `toc.json` поддерживает вложенные категории (элементы `items` могут содержать подкатегории с собственными `items` или статьи с `files`). См. раздел «Вложенные категории» в [Формат toc.json](docs/toc_format.md).

## Документация

- [Подготовка](docs/prepare.md)
- [Быстрый старт](docs/quickstart.md)
- [Структура проекта](docs/structure.md)
- [Формат toc.json](docs/toc_format.md)
- [Изображения и AVIF](docs/images.md)
- [Валидация toc.json](docs/validation.md)
- [Ссылки и якоря в статьях](docs/links.md)
- [Нормализация названий статей (snake_case)](docs/normalization.md)

## Локальные команды (Node.js)

Рекомендуемый способ работы (Windows/macOS/Linux) — через Node.js без Docker:

```bash
cd src/game-lore-library
npm ci

# Валидация оглавления (stage и production)
npm run validate:toc

# Проверка ссылок (без изменения файлов)
npm run validate:links

# Автопочинка ссылок/якорей
npm run fix:links

# Нормализация имён файлов и папок статей (stage)
npm run normalize

# Конвертация изображений в AVIF
npm run images:avif        # оба окружения
# npm run images:avif:stage
# npm run images:avif:production
```

## Установка Node.js и запуск из VS Code

- Установите Node.js LTS: https://nodejs.org (выберите LTS)
- Откройте репозиторий в VS Code (или другом редакторе)
- В VS Code:
  - Откройте вкладку «NPM Scripts» (вкладка Explorer → раздел NPM Scripts)
  - Запускайте нужные команды кликом: `validate:toc`, `validate:links`, `fix:links`, `normalize`, `images:avif`
  - Либо откройте встроенный терминал (View → Terminal) и выполните команды из раздела выше
