# Валидация toc.json и статей

[← Назад к README](../README.md)

Скрипт `validate_toc.sh` проверяет корректность `toc.json` и наличие указанных файлов.

## Что проверяется

- Валидность JSON и наличие секций `WIKI`, `LORE`
- Структура категорий и статей
- Наличие файлов статей на диске
- Соответствие языковых ключей суффиксам файлов (`_ru.md` / `_en.md`)

## Запуск через Docker

```bash
cd src/game-lore-library
```

```bash
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

---

См. также: [Формат toc.json](toc_format.md)
