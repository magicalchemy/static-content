# Выбор приложения для редактирования Markdown

[← Назад к README](../README.md)

- **Visual Studio Code** (Windows/macOS/Linux) — **бесплатно, open‑source**. Универсальный редактор с встроенным предпросмотром Markdown.
  - Скачать: https://code.visualstudio.com/download
  - Превью: откройте `.md` → «Open Preview to the Side»
    - Windows/Linux: Ctrl+Shift+V
    - macOS: ⌘⇧V

## Запуск npm‑скриптов в VS Code

- Откройте папку репозитория в VS Code.
- В боковой панели откройте «NPM Scripts» (Explorer → NPM Scripts).
- Запускайте нужные команды двойным кликом: `validate:toc`, `validate:links`, `fix:links`, `normalize`, `images:avif`.
- Альтернатива: встроенный терминал (View → Terminal):

```bash
cd src/game-lore-library
npm ci
npm run validate:toc
```
