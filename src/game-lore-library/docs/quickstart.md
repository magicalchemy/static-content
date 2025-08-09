# Быстрый старт: добавление новой статьи

[← Назад к README](../README.md)

Эта инструкция описывает, как добавить новую статью в базу знаний игры.

## Работа с файлами и репозиторием

Для начала склонируйте репозиторий:

```bash
git clone https://github.com/magicalchemy/static-content.git
cd static-content
```

Подробнее: [Подготовка](../prepare.md)

## Обновление контента на stage

### 1. Создайте папку для новой статьи

В директории `src/game-lore-library/stage/articles/` создайте новую папку с названием вашей статьи (без пробелов,
используйте нижние подчеркивания).

Пример: `src/game-lore-library/stage/articles/dragons_of_the_north/`

### 2. Добавьте файлы статьи

В созданной папке создайте файлы статей с расширением `.md`:

- Основной файл на русском языке: `dragons_of_the_north_ru.md`
- Если нужна английская версия: `dragons_of_the_north_en.md`

▶ Предпросмотр Markdown (без сборки)
- Рекомендуем VS Code: откройте `.md` файл → «Open Preview to the Side»
  - Windows/Linux: Ctrl+Shift+V
  - macOS: ⌘⇧V
Подробнее: [Выбор приложения](prepare_editors.md)

### 3. Добавьте изображения

Если в статье есть изображения:

1. Создайте папку `images` внутри папки статьи
2. Поместите изображения в эту папку в формате `.2x.png` или `.2x.jpg`
3. Пример пути: `dragons_of_the_north/images/dragon-fire.2x.png`

### 4. Конвертируйте изображения в AVIF

После добавления всех изображений запустите инструмент конвертации, чтобы создать AVIF-версии (см. [Конвертация изображений](images.md)).

### 5. Добавьте статью в оглавление

Откройте `src/game-lore-library/stage/toc.json` и добавьте вашу статью в соответствующий раздел (WIKI или LORE)
согласно формату, описанному в [Формат toc.json](toc_format.md).

Подсказка по ссылкам и якорям в тексте статей: см. [Ссылки и якоря](links.md).
Требование к `{#id}`: латиница, дефисы, цифры; без пробелов.

### 6. Проверка и публикация

- Запустите валидацию `toc.json` (см. [Валидация toc.json](validation.md)):

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

- Протестируйте на stage, по raw-ссылке, и на сайте:

```
https://raw.githubusercontent.com/magicalchemy/static-content/refs/heads/main/src/game-lore-library/stage/toc.json
```

Сайт: https://stage.magicalchemy.org/world/library

- При готовности продвиньте изменения в production:

  - Скопируйте статьи из `stage/articles/` в `production/articles/`
  - Скопируйте `stage/toc.json` в `production/toc.json`

- Закоммитьте и запушьте изменения:

```bash
git commit -m "update game lore articles in production"
```

```bash
git push origin main
```

- Протестируйте на production по raw-ссылке и на сайте:

```
https://raw.githubusercontent.com/magicalchemy/static-content/refs/heads/main/src/game-lore-library/production/toc.json
```

Сайт: https://magicalchemy.org/world/library
