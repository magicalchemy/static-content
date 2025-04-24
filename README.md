# MA Static Content

## Описание

Репозиторий хранит статические данные для фронтенда нашей игры:

- **marathon-broadcasts**: JSON-файлы трансляций (stage/production)
- **game-lore-library**: markdown-статьи и изображения (stage/production)

## Структура

```bash
MA-static-content/
├── src/
│   ├── marathon-broadcasts/
│   └── game-lore-library/
└── README.md
```

Подпапки каждого подпроекта:

```bash
src/marathon-broadcasts/
├── stage/
│   └── broadcasts.json
└── production/
    └── broadcasts.json

src/game-lore-library/
├── stage/
│   ├── toc.json
│   ├── articles/
│   └── images/
└── production/
    ├── toc.json
    ├── articles/
    └── images/
```

## Работа с репозиторием

1. Клонировать:
   ```bash
   git clone https://github.com/magicalchemy/static-content.git
   cd static-content
   ```
2. внести изменения в подпроект для stage
3. закоммитить изменения `git commit -m "update marathon broadcasts"`
4. залить изменения на github `git push origin main`
5. протестировать на stage
6. если все хорошо скопировать `stage/*` → `production/*` и мержить.

## Подпроекты

- [marathon-broadcasts](src/marathon-broadcasts/README.md)
- [game-lore-library](src/game-lore-library/README.md)
