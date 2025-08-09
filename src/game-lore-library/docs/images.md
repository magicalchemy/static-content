# Изображения и конвертация в AVIF

[← Назад к README](../README.md)

## Форматы
- Исходные: `.2x.png`, `.2x.jpg`, `.2x.jpeg`
- Целевые: `.2x.avif`, `.1x.avif`, `.mobile.2x.avif`, `.mobile.1x.avif`
- Хранить в `images/` внутри папки статьи.

## Конвертация (Docker — рекомендуется)

```bash
cd src/game-lore-library
docker build -t avif-converter .
docker run --rm -v "$(pwd)/stage:/app/stage" avif-converter --environment stage
# или для production
# docker run --rm -v "$(pwd)/production:/app/production" avif-converter --environment production
```

## Конвертация локально

macOS:
```bash
brew install imagemagick libavif
cd src/game-lore-library
chmod +x convert_to_avif.sh
./convert_to_avif.sh
```

Скрипт автоматически создаёт версии AVIF, не изменяет оригиналы и пропускает уже существующие `.avif` файлы.

## Что делает конвертер

Конвертер автоматически:

- Находит все картинки `.2x.png`, `.2x.jpg` или `.2x.jpeg` в папках статей
- Создаёт несколько версий каждого изображения в формате AVIF:
  - `.2x.avif` — полноразмерная версия
  - `.1x.avif` — уменьшенная в два раза версия
  - `.mobile.2x.avif` — версия для мобильных устройств (≈55% от оригинала)
  - `.mobile.1x.avif` — уменьшенная версия для мобильных устройств
- Сохраняет новые файлы рядом с оригиналами в той же папке
- Не трогает оригинальные файлы
- Пропускает уже созданные AVIF файлы (для пересоздания удалите старые файлы вручную)

## Как запустить конвертацию изображений

### Самый простой способ (Windows, macOS, Linux)

1. Установите Docker Desktop и запустите его
2. Откройте терминал и перейдите в `src/game-lore-library`
3. Выполните одну команду для stage:

```bash
docker build -t avif-converter . && docker run --rm -v "$(pwd)/stage:/app/stage" avif-converter --environment stage
```

Готово — все необходимые AVIF-версии изображений будут созданы.
