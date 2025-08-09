# Подготовка: GitHub Desktop (без терминала)

[← Назад к README](../README.md)

Рекомендуемый путь для новичков — работать через **GitHub Desktop** (Windows/macOS) без терминала.

## Установка

- Сайт: https://desktop.github.com/
- Установите и запустите приложение

## Первый запуск и вход

1. Нажмите «Sign in to GitHub» и войдите в свой аккаунт
2. Если у вас нет доступа к репозиторию — обратитесь к технарям

## Клонирование репозитория

1. File → Clone repository…
2. Вкладка «URL» → вставьте:
   - HTTPS: `https://github.com/magicalchemy/static-content.git`
   - или SSH: `git@github.com:magicalchemy/static-content.git` (если настроены ключи)
3. Выберите папку на диске → Clone

## Редактирование статей

1. В проводнике системы откройте папку: `static-content/src/game-lore-library`
2. Редактируйте `.md` файлы выбранным приложением (см. «[Выбор редактора](prepare_editors.md)»)
   - Полезные ссылки: «Быстрый старт» — `quickstart.md`, «Ссылки и якоря» — `links.md`

## Коммит и отправка изменений

1. Вернитесь в GitHub Desktop — изменения отобразятся в списке
2. Введите короткое описание (Summary)
3. Нажмите «Commit to main»
4. Нажмите «Push origin» (отправить на GitHub)

### Подсказки

- Если GitHub Desktop попросит логин/пароль — используйте Personal Access Token (PAT) как пароль (см. «[Git из терминала](prepare_git_cli.md) → HTTPS + PAT»)
- При проблемах с доступом или правами — обратитесь к технарям
