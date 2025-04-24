# Marathon Broadcasts

## Описание

Данный подпроект хранит JSON-файлы с данными о текущих или предстоящих трансляциях на платформах YouTube и Twitch.

## Структура

```bash
src/marathon-broadcasts/
├── stage/
│   └── broadcasts.json   # черновая версия для stage
└── production/
    └── broadcasts.json   # стабильная версия для prod
```

## Формат JSON

```json
{
  "youtube_url": "https://youtube.com/..." или "",
  "twitch_url": "https://twitch.tv/..." или "",
  "is_live": true | false,
  "scheduled_time": "YYYY-MM-DDTHH:MM:SSZ" (ISO 8601)  // опционально
}
```

## Ожидаемое поведение

- Если `youtube_url` или `twitch_url` заполнены, на сайте отображается кнопка перехода.
- Поле `is_live` определяет, будет ли кнопка активной.
- При отсутствии ссылок — кнопка не отображается.

## Работа с файлами

1. Клонировать репозиторий:
   ```bash
   git clone https://github.com/<org>/MA-static-content.git
   cd MA-static-content
   ```
2. Создать ветку для изменений:
   ```bash
   git checkout -b update-broadcasts
   ```
3. Обновить `src/marathon-broadcasts/stage/broadcasts.json`.
4. Протестировать на stage через raw-ссылку:
   ```
   https://raw.githubusercontent.com/<org>/MA-static-content/main/src/marathon-broadcasts/stage/broadcasts.json
   ```
5. Создать Pull Request, после одобрения скопировать `stage/broadcasts.json` → `production/broadcasts.json` и мержить.
