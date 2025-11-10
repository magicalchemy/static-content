# Scripts

## Add Version Script

Скрипт для добавления новых версий игры в систему обновлений.

### Использование

```bash
node scripts/add-version-simple.js
```

### Что делает скрипт:

1. Запрашивает номер версии (формат: X.Y.Z, например 0.4.399)
2. Запрашивает дату релиза (формат: YYYY-MM-DD, по умолчанию - сегодня)
3. Запрашивает тип обновления:
   - `feature` - новая функциональность
   - `fix` - исправление ошибок
   - `update` - обновление существующей функциональности
4. Создаёт папку версии в `src/game-versions/stage/versions/{version}/`
5. Создаёт файлы `en.md` и `ru.md` с шаблонами
6. Обновляет `src/game-versions/stage/updates.json`

### Пример

```
🎮 Magic Alchemy - Add New Version

Enter version (e.g., 0.4.399): 0.4.400
Enter date (YYYY-MM-DD) [2025-11-07]:
Enter type (feature/fix/update): feature

✅ Created directory: /path/to/src/game-versions/stage/versions/0.4.400
✅ Created file: /path/to/src/game-versions/stage/versions/0.4.400/en.md
✅ Created file: /path/to/src/game-versions/stage/versions/0.4.400/ru.md
✅ Updated: /path/to/src/game-versions/stage/updates.json

🎉 Version added successfully!

Summary:
  Version: 0.4.400
  Date: 2025-11-07
  Type: feature

Next steps:
  1. Edit en.md
  2. Edit ru.md
```

### Валидация

Скрипт проверяет:
- Формат версии (должен быть X.Y.Z)
- Уникальность версии (не существует ли уже)
- Формат даты (YYYY-MM-DD)
- Тип обновления (feature/fix/update)
