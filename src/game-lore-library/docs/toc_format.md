# Формат toc.json

[← Назад к README](../README.md)

`toc.json` поддерживает мультиязычные статьи и категории, разделённые на секции `WIKI` и `LORE`.
Элементы верхнего уровня внутри `WIKI`/`LORE` могут быть как категориями (с `items`), так и самостоятельными статьями (c `files`).

## Базовая структура

```json
{
  "WIKI": [
    { "title": {"ru": "Категория", "en": "Category"}, "items": [ /* статьи/подкатегории */ ] },
    { "title": {"ru": "Статья", "en": "Article"}, "files": {"ru": "articles/..._ru.md", "en": "articles/..._en.md"} }
  ],
  "LORE": [
    { "title": {"ru": "Категория", "en": "Category"}, "items": [ /* статьи/подкатегории */ ] },
    { "title": {"ru": "Статья", "en": "Article"}, "files": {"ru": "articles/..._ru.md", "en": "articles/..._en.md"} }
  ]
}
```

## Опциональный «Таинственный листок» (`MYSTERIOUS_NOTE`) {#опциональный-таинственный-листок-mysterious_leaf}

- В корне `toc.json` может присутствовать дополнительный ключ `MYSTERIOUS_NOTE`.
- Его значение — объект того же формата, что и `files` у статьи: допустимы языковые ключи `ru` и/или `en`.
- Поле опционально: если его нет — это не ошибка. Если есть — пути должны соответствовать правилам файлов статей.

Пример:

```json
{
  "WIKI": [],
  "LORE": [],
  "MYSTERIOUS_NOTE": {
    "ru": "articles/MYSTERIOUS_NOTE/note_ru.md",
    "en": "articles/MYSTERIOUS_NOTE/note_en.md"
  }
}
```

Правила для `MYSTERIOUS_NOTE`:

- Разрешены только существующие языковые ключи (`ru`/`en`), как и для обычных `files`.
- Пути обязаны быть валидными и соответствовать суффиксам `_ru.md`/`_en.md`.
- Схема `toc.schema.json` допускает это поле, но не требует его наличия.

## Вложенные категории

Теперь элементы внутри `items` (а также верхнего уровня секций) могут быть двух типов:

- Статья: объект с `title` и `files` (как описано выше).
- Подкатегория: объект с `title` и вложенным массивом `items`.

Правила для подкатегорий:

- Поля `title.ru` и `title.en` обязательны на любом уровне вложенности.
- Подкатегория не должна содержать `files` — только `items`.
- Статья не должна содержать `items` — только `files`.
- Глубина вложенности не ограничена, но придерживайтесь здравого смысла (KISS/YAGNI).

Мини‑пример со вложенностью:

```json
{
  "WIKI": [
    {
      "title": {"ru": "Механики", "en": "Game Mechanics"},
      "items": [
        {
          "title": {"ru": "Боевая система", "en": "Combat System"},
          "items": [
            {
              "title": {"ru": "Оружие", "en": "Weapons"},
              "items": [
                {
                  "title": {"ru": "Мечи", "en": "Swords"},
                  "files": {
                    "ru": "articles/swords/swords_ru.md",
                    "en": "articles/swords/swords_en.md"
                  }
                }
              ]
            }
          ]
        }
      ]
    }
  ],
  "LORE": []
}
```

## Элемент статьи

```json
{
  "title": {"ru": "Название на русском", "en": "Title in English"},
  "files": {
    "ru": "articles/Название_статьи/Название_статьи_ru.md",
    "en": "articles/Название_статьи/Название_статьи_en.md"
  }
}
```

Правила:
- Если файла на языке нет — не указывайте ключ (не ставьте `null`).
- Путь обязан указывать на существующий файл и соответствовать суффиксу языка (`_ru.md` / `_en.md`).
- Русский ключ не должен ссылаться на `_en.md`, и наоборот — это ошибка формата.

### Статья на верхнем уровне секции

Допускается размещать статью напрямую в массиве `WIKI` или `LORE` (без категории):

```json
{
  "WIKI": [
    {
      "title": {"ru": "NFT COLLECTION MAGIC ALCHEMY", "en": "NFT COLLECTION MAGIC ALCHEMY"},
      "files": {
        "ru": "articles/nft_2/nft_ru.md",
        "en": "articles/nft_2/nft_en.md"
      }
    }
  ],
  "LORE": []
}
```

## Категория со статьями

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

## Мини‑пример: добавляем одну статью (до/после)

Исходный фрагмент `stage/toc.json` (категория уже есть, статей пока нет):

```json
{
  "WIKI": [
    {
      "title": {"ru": "Механики", "en": "Game Mechanics"},
      "items": []
    }
  ],
  "LORE": []
}
```

После добавления одной статьи (только RU‑версия, EN отсутствует — ключ не указываем):

```json
{
  "WIKI": [
    {
      "title": {"ru": "Механики", "en": "Game Mechanics"},
      "items": [
        {
          "title": {"ru": "Боевая система"},
          "files": {
            "ru": "articles/boevaya_sistema/boevaya_sistema_ru.md"
          }
        }
      ]
    }
  ],
  "LORE": []
}
```

Подсказки:
- Указывайте только существующие языковые ключи.
- Путь обязан быть валидным и соответствовать суффиксу (`_ru.md` / `_en.md`).
- Нейминг путей — латиница, `lower_snake_case` (см. «Структура проекта»).

## Пример полной структуры

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
            "ru": "articles/combat_system/combat_system_ru.md",
            "en": "articles/combat_system/combat_system_en.md"
          }
        },
        {
          "title": {
            "ru": "Ребаланс Magic Towers",
            "en": "Magic Towers Rebalance"
          },
          "files": {
            "ru": "articles/magic_towers_rebalance/magic_towers_rebalance_ru.md",
            "en": "articles/magic_towers_rebalance/magic_towers_rebalance_en.md"
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
            "ru": "articles/about_magical_creatures/about_magical_creatures_ru.md",
            "en": "articles/about_magical_creatures/about_magical_creatures_en.md"
          }
        },
        {
          "title": {
            "ru": "Страны мира ДжиДа",
            "en": "JiDa World Countries"
          },
          "files": {
            "ru": "articles/jida_world_countries_part_4/jida_world_countries_part_4_ru.md",
            "en": "articles/jida_world_countries_part_4/jida_world_countries_part_4_en.md"
          }
        }
      ]
    }
  ]
}
```

## Дополнительно

- Разрешено указывать только те языковые ключи, для которых реально существует файл.
- Отсутствие перевода — это нормально; валидатор сообщит предупреждением (warning), но не ошибкой.
- Для проверки корректности структуры используйте `validate_toc.sh` (см. [Валидация](validation.md)).
