# Валидация toc.json и статей

[← Назад к README](../README.md)

Скрипт `validate_toc.sh` проверяет корректность `toc.json` и наличие указанных файлов.

## Быстрый запуск (через меню утилит)

Рекомендуется использовать общее меню утилит — оно само соберёт образ и смонтирует каталоги корректно:

```bash
cd src/game-lore-library
chmod +x ma-tools.sh
./ma-tools.sh
```

Далее выберите пункт «Валидация toc.json», укажите окружение (stage/production/both) и, при необходимости, включите verbose.

## Что проверяется

- Валидность JSON и наличие секций `WIKI`, `LORE`
- Структура категорий и статей (рекурсивно, поддерживаются вложенные категории)
- Наличие файлов статей на диске
- Соответствие языковых ключей суффиксам файлов (`_ru.md` / `_en.md`)

## Запуск через Docker (вручную)

Сборка образа:

```bash
cd src/game-lore-library
docker build -t toc-validator -f Dockerfile.validator .
```

```bash
# Проверка обоих окружений
docker run --rm -v "$(pwd):/app" toc-validator
```

```bash
# Только stage
docker run --rm -v "$(pwd):/app" toc-validator -e stage
```

```bash
# Только production
docker run --rm -v "$(pwd):/app" toc-validator -e production
```

```bash
# Подробный вывод
docker run --rm -v "$(pwd):/app" toc-validator -v
```

Примечание: если вы уже собирали образ через меню (`ma-tools.sh`), он имеет тег `ma-gl-validator`. Можно использовать его вместо `toc-validator`:

```bash
docker run --rm -v "$(pwd):/app" ma-gl-validator -e both -v
```

---

См. также: [Формат toc.json](toc_format.md)
