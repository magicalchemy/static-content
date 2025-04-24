# Game Lore Library

## Описание

Данный подпроект хранит статьи по лору игры и механикам в виде markdown-файлов, связанных через файл оглавления.

## Структура

src/game-lore-library/
├── stage/
│ ├── toc.json # оглавление статей
│ ├── articles/ # markdown-статьи
│ │ └── example.md
│ └── images/ # картинки для статей
│ └── .gitkeep
└── production/
├── toc.json
├── articles/
│ └── example.md
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
   git clone https://github.com/magicalchemy/static-content.git
   cd static-content
   ```

2. Обновить статьи в `src/game-lore-library/stage/articles` и изображения в `src/game-lore-library/stage/images`.

3. Обновить `src/game-lore-library/stage/toc.json`.

4. Закоммитить изменения:

   ```bash
   git commit -m "update game lore articles"
   ```

5. Залить изменения на GitHub:

   ```bash
   git push origin main
   ```

6. Протестировать на stage через raw-ссылку:

   ```
   https://raw.githubusercontent.com/magicalchemy/static-content/refs/heads/main/src/game-lore-library/stage/toc.json
   ```

   и на сайте https://stage.magicalchemy.org/world/library

7. Если все хорошо, скопировать содержимое из `stage/` в `production/`:

   - Скопировать статьи из `stage/articles/` в `production/articles/`
   - Скопировать изображения из `stage/images/` в `production/images/`
   - Скопировать `stage/toc.json` в `production/toc.json`

8. Закоммитить изменения:

   ```bash
   git commit -m "update game lore articles in production"
   ```

9. Залить изменения на GitHub:

   ```bash
   git push origin main
   ```

10. Протестировать на production через raw-ссылку:
    ```
    https://raw.githubusercontent.com/magicalchemy/static-content/refs/heads/main/src/game-lore-library/production/toc.json
    ```
    и на сайте https://magicalchemy.org/world/library
