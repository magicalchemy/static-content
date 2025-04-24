# Game Lore Library

## Описание

Данный подпроект хранит статьи по лору игры и механикам в виде markdown-файлов, связанных через файл оглавления.

## Структура

src/game-lore-library/
├── stage/
│   ├── toc.json         # оглавление статей
│   ├── articles/        # markdown-статьи
│   │   └── example.md
│   └── images/          # картинки для статей
│       └── .gitkeep
└── production/
    ├── toc.json
    ├── articles/
    │   └── example.md
    └── images/
        └── .gitkeep

## Формат toc.json

```json
[
  {
    "title": "Название статьи",
    "file": "articles/filename.md"
  }
]
```

## Ожидаемое поведение

- Фронтенд импортирует `toc.json`, загружает статьи и изображения через raw-ссылки.
- Каждая статья отображается с заголовком и контентом.
- Картинки доступны из папки `images`.

## Работа с файлами

1. Клонировать репозиторий:
```bash
git clone https://github.com/<org>/MA-static-content.git
cd MA-static-content
```
2. Создать ветку:
```bash
git checkout -b update-lore
```
3. Добавить/обновить статьи в `src/game-lore-library/stage/articles` и изображения в `src/game-lore-library/stage/images`.
4. Обновить `src/game-lore-library/stage/toc.json`.
5. Протестировать на stage:
```
https://raw.githubusercontent.com/<org>/MA-static-content/main/src/game-lore-library/stage/toc.json
```
6. Создать Pull Request, после мержа копировать `stage/*` → `production/*` и мержить.
