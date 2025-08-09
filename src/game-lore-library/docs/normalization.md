# Нормализация названий статей (snake_case)

Если нужно выправить названия директорий и файлов статей в окружении `stage/` к единому формату латиницей в lowercase с подчёркиваниями (snake_case), используйте скрипт:

```bash
# из корня репозитория
chmod +x src/game-lore-library/normalize_stage_article_names.sh
src/game-lore-library/normalize_stage_article_names.sh
```

## Что делает скрипт `src/game-lore-library/normalize_stage_article_names.sh`

- Преобразует имена директорий и файлов в `src/game-lore-library/stage/articles/`:
  - транслитерация кириллицы → латиница,
  - приведение к lowercase и замена разделителей на `_` (snake_case),
  - сохранение языковых суффиксов `_ru.md` и `_en.md`.
- Переименовывает безопасно (через временные имена) и обновляет пути в `src/game-lore-library/stage/toc.json`.
- Создаёт бэкап `toc.json` рядом (`toc.json.bak`).

## Требования и примечания

- Достаточно стандартных утилит macOS: `bash`, `awk`, `sed` (внешние зависимости не нужны).
- Запускать из корня репозитория.
- Скрипт автоматически добавляет изменения в индекс Git (`git add -A src/game-lore-library/stage`), но коммит необходимо сделать отдельно.
- Идемпотентен: корректные имена не меняются повторно.

## Быстрый запуск (через меню утилит)

Рекомендуется использовать общее меню утилит — оно само соберёт образ и смонтирует каталоги корректно:

```bash
cd src/game-lore-library
chmod +x ma-tools.sh
./ma-tools.sh
```

Далее выберите пункт «Нормализация названий (snake_case)».

## Запуск через Docker

Рекомендуемый способ — собрать лёгкий образ один раз и переиспользовать:

```bash
# сборка образа с нужными инструментами
docker build -t ma-gl-normalize -f src/game-lore-library/Dockerfile.normalize .
```

```bash
# запуск скрипта нормализации
docker run --rm -it \
  -v "$PWD:/work" -w /work \
  ma-gl-normalize bash -lc 'bash src/game-lore-library/normalize_stage_article_names.sh && git status -s'
```

## Проверка результатов

После выполнения рекомендуется проверить изменения:

```bash
git status -s
```
