# Валидация toc.json и статей

[← Назад к README](../README.md)

Рекомендуемый способ — Node-скрипты:

```bash
cd src/game-lore-library
npm ci

# Проверка toc.json (stage и production)
npm run validate:toc

# Проверка ссылок/якорей без изменений файлов
npm run validate:links

# Автопочинка ссылок/якорей
npm run fix:links
```

## Что проверяется

- Валидность JSON и наличие секций `WIKI`, `LORE`
- Структура категорий и статей (рекурсивно, поддерживаются вложенные категории)
- Наличие файлов статей на диске
- Соответствие языковых ключей суффиксам файлов (`_ru.md` / `_en.md`)

---

См. также: [Формат toc.json](toc_format.md)
