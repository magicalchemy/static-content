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
   git clone https://github.com/<org>/MA-static-content.git
   cd MA-static-content
   ```
2. Создать ветку для изменений в нужном подпроекте:
   ```bash
   git checkout -b update-<subproject>
   ```
3. Обновить файлы в `src/<subproject>/stage/`.
4. Протестировать через raw-ссылки:
   ```bash
   https://raw.githubusercontent.com/<org>/MA-static-content/main/src/<subproject>/stage/...
   ```
5. Создать Pull Request, после мержа скопировать `stage/*` → `production/*` и мержить.

## Подпроекты
- [marathon-broadcasts](src/marathon-broadcasts/README.md)
- [game-lore-library](src/game-lore-library/README.md)