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

```
{
  "youtube_url": "https://youtube.com/..." или "",
  "twitch_url": "https://twitch.tv/..." или "",
  "is_live": true или false,
}
```

## Ожидаемое поведение

- Если `youtube_url` или `twitch_url` заполнены, на сайте отображается кнопка перехода.
- Поле `is_live` определяет, будет ли кнопка активной.
- При отсутствии ссылок — кнопка не отображается.

## Работа с файлами

1. Клонировать репозиторий:
   ```bash
   git clone https://github.com/magicalchemy/static-content.git
   cd static-content
   ```
2. Обновить `src/marathon-broadcasts/stage/broadcasts.json`.

3. закоммитить изменения `git commit -m "update marathon broadcasts"`

4. залить изменения на github `git push origin main`

5. протестировать на stage через raw-ссылку:

   ```
   https://raw.githubusercontent.com/magicalchemy/static-content/refs/heads/main/src/marathon-broadcasts/stage/broadcasts.json
   ```

   и на сайте https://stage.magicalchemy.org/world/altar

6. протестировть на stage

7. если все хорошо скопировать `stage/broadcasts.json` → `production/broadcasts.json`

8. закоммитить изменения git commit -m "update marathon broadcasts"

9. залить изменения на github git push origin main.

10. протестировать на production через raw-ссылку:
    ```
    https://raw.githubusercontent.com/magicalchemy/static-content/refs/heads/main/src/marathon-broadcasts/production/broadcasts.json
    ```
    и на сайте https://magicalchemy.org/world/altar
