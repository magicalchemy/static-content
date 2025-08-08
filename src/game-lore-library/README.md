# Game Lore Library

## Описание

Данный подпроект хранит статьи по лору игры и механикам в виде markdown-файлов, связанных через файл оглавления.

## Структура

src/game-lore-library/
├── stage/
│ ├── toc.json # оглавление статей
│ └── articles/ # markdown-статьи
│     ├── [Название_статьи]/ # отдельная директория для каждой статьи
│     │   ├── [Название_статьи]_ru.md # файл статьи на русском
│     │   ├── [Название_статьи]_en.md # файл статьи на английском (опционально)
│     │   └── images/ # изображения для конкретной статьи
└── production/
    ├── toc.json
    └── articles/

## Формат toc.json

Файл `toc.json` поддерживает мультиязычные статьи и категории, разделенные на две основные секции: WIKI и LORE.

### 1. Структура файла

Файл представляет собой JSON-объект с двумя ключами "WIKI" и "LORE", значениями которых являются массивы статей и категорий.

```json
{
  "WIKI": [...],
  "LORE": [...]
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
