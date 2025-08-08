#!/bin/bash

# Скрипт для конвертации изображений в формат AVIF
# Берет изображения *.2x.png/jpg/jpeg из директорий статей и создает их AVIF-версии
# Сохраняет результаты в те же директории, не удаляя исходные файлы

# Параметры по умолчанию
ENVIRONMENT="stage"

# Обработка параметров командной строки
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -e|--environment) ENVIRONMENT="$2"; shift ;;
        *) echo "Неизвестный параметр: $1"; exit 1 ;;
    esac
    shift
done

# Проверка корректности окружения
if [[ "$ENVIRONMENT" != "stage" && "$ENVIRONMENT" != "production" ]]; then
    echo "Ошибка: окружение должно быть 'stage' или 'production'."
    exit 1
fi

echo "Используемое окружение: $ENVIRONMENT"

# Проверка, запущен ли скрипт в Docker
if [ -f "/.dockerenv" ]; then
    echo "Запуск в режиме Docker"
    articles_folder="/app/$ENVIRONMENT/articles"
else
    echo "Запуск в обычном режиме"
    # Основная директория со статьями
    articles_folder="/Users/egortrubnikov-panov/WebstormProjects/MA-static-content/src/game-lore-library/$ENVIRONMENT/articles"
fi

# Разрешения и коэффициенты масштабирования
resolutions=(
    "desktop 1"      # десктопная версия
    "mobile 0.55"    # мобильная версия (55% от оригинала)
)

# Определение операционной системы
detect_os() {
    case "$(uname -s)" in
        Linux*)     OS="Linux";;
        Darwin*)    OS="MacOS";;
        CYGWIN*|MINGW*|MSYS*)    OS="Windows";;
        *)          OS="Unknown";;
    esac
    echo "$OS"
}

OS=$(detect_os)
echo "Операционная система: $OS"

# Функция для проверки наличия необходимых утилит
check_dependencies() {
    missing_deps=()
    
    if ! command -v convert &> /dev/null; then
        missing_deps+=("ImageMagick (convert)")
    fi
    
    if ! command -v identify &> /dev/null; then
        missing_deps+=("ImageMagick (identify)")
    fi
    
    if ! command -v avifenc &> /dev/null; then
        missing_deps+=("avifenc")
    fi
    
    if [ ${#missing_deps[@]} -ne 0 ]; then
        echo "Ошибка: отсутствуют необходимые зависимости:"
        for dep in "${missing_deps[@]}"; do
            echo "- $dep"
        done
        echo ""
        echo "Установите недостающие зависимости:"
        
        case "$OS" in
            "MacOS")
                echo "  - ImageMagick: brew install imagemagick"
                echo "  - libavif: brew install libavif"
                ;;
            "Linux")
                echo "  - ImageMagick: sudo apt-get install imagemagick"
                echo "  - libavif: sudo apt-get install libavif-bin"
                ;;
            "Windows")
                echo "  - ImageMagick: Скачайте с https://imagemagick.org/script/download.php"
                echo "  - libavif: Используйте WSL или скомпилируйте из https://github.com/AOMediaCodec/libavif"
                ;;
            *)
                echo "  - Установите ImageMagick и libavif для вашей операционной системы"
                ;;
        esac
        
        exit 1
    fi
}

# Проверяем зависимости
check_dependencies

# Счетчики для статистики
total_files=0
processed_files=0
skipped_files=0

# Создаем временный файл для отслеживания статистики
TEMP_STATS="/tmp/avif_conversion_stats_$$.tmp"
echo "0 0 0" > "$TEMP_STATS"

echo "Начинаем обработку изображений..."

# Функция для обновления статистики
update_stats() {
    local type=$1
    read total proc skip < "$TEMP_STATS"
    
    case "$type" in
        "total") ((total++)) ;;
        "proc")  ((proc++))  ;;
        "skip")  ((skip++))  ;;
    esac
    
    echo "$total $proc $skip" > "$TEMP_STATS"
}

# Находим все изображения в формате .2x.png/jpg/jpeg во всех поддиректориях
find "$articles_folder" -type d -name "images" | while read -r img_dir; do
    echo "Обрабатываем директорию: $img_dir"
    
    # Находим все изображения в форматах .2x.png, .2x.jpg, .2x.jpeg
    find "$img_dir" -type f \( -name "*.2x.png" -o -name "*.2x.jpg" -o -name "*.2x.jpeg" \) | while read -r file; do
        update_stats "total"
        
        # Получаем информацию о файле
        directory=$(dirname "$file")
        filename=$(basename "$file")
        base_name="${filename%.*}"        # Удаляем последнее расширение (.png/.jpg/.jpeg)
        base_name="${base_name%.*}"       # Удаляем .2x
        extension="${filename##*.}"       # Получаем расширение
        
        echo "Обработка файла: $filename"
        
        for resolution in "${resolutions[@]}"; do
            res=$(echo $resolution | cut -d' ' -f1)
            scale=$(echo $resolution | cut -d' ' -f2)
            
            # Получаем размеры исходного изображения
            width=$(identify -format "%w" "$file")
            height=$(identify -format "%h" "$file")
            
            # Новые размеры изображения для .2x версии с округлением до целых чисел
            new_width_2x=$(echo "$width * $scale" | bc -l | awk '{print int($1)}')
            new_height_2x=$(echo "$height * $scale" | bc -l | awk '{print int($1)}')
            
            # Новые размеры изображения для .1x версии (50% от .2x)
            new_width_1x=$(echo "$new_width_2x * 0.5" | bc -l | awk '{print int($1)}')
            new_height_1x=$(echo "$new_height_2x * 0.5" | bc -l | awk '{print int($1)}')
            
            # Генерация имен файлов для .2x и .1x в зависимости от разрешения
            if [ "$res" = "desktop" ]; then
                target_file_2x_avif="${directory}/${base_name}.2x.avif"
                target_file_1x_avif="${directory}/${base_name}.1x.avif"
            elif [ "$res" = "mobile" ]; then
                target_file_2x_avif="${directory}/${base_name}.${res}.2x.avif"
                target_file_1x_avif="${directory}/${base_name}.${res}.1x.avif"
            else
                # Пропускаем неизвестные разрешения
                echo "Неизвестное разрешение: $res, пропускаем."
                continue
            fi
            
            # Проверка существования 2x и 1x файлов
            need_2x=true
            need_1x=true
            
            # Проверяем существование .2x файла
            if [ -f "$target_file_2x_avif" ]; then
                echo "   Пропускаем: $target_file_2x_avif уже существует"
                update_stats "skip"
                need_2x=false
            fi
            
            # Проверяем существование .1x файла
            if [ -f "$target_file_1x_avif" ]; then
                echo "   Пропускаем: $target_file_1x_avif уже существует"
                update_stats "skip"
                need_1x=false
            fi
            
            # Если оба файла уже существуют, пропускаем этот ресурс
            if [ "$need_2x" = false ] && [ "$need_1x" = false ]; then
                continue
            fi
            
            # Создание .2x версии если нужно
            if [ "$need_2x" = true ]; then
                # Генерация временного PNG и конвертация в AVIF для .2x
                temp_png_2x="${target_file_2x_avif}.temp.png"
                convert "$file" -resize ${new_width_2x}x${new_height_2x}\! "$temp_png_2x"
                avifenc --depth 8 --min 16 --max 20 "$temp_png_2x" "$target_file_2x_avif"
                rm "$temp_png_2x"  # Удаляем временный PNG
                
                update_stats "proc"
                echo "   AVIF создан: $target_file_2x_avif"
            fi
            
            # Создание .1x версии если нужно
            if [ "$need_1x" = true ]; then
                # Генерация временного PNG и конвертация в AVIF для .1x
                temp_png_1x="${target_file_1x_avif}.temp.png"
                convert "$file" -resize ${new_width_1x}x${new_height_1x}\! "$temp_png_1x"
                avifenc --depth 8 --min 16 --max 20 "$temp_png_1x" "$target_file_1x_avif"
                rm "$temp_png_1x"  # Удаляем временный PNG
                
                update_stats "proc"
                echo "   AVIF создан: $target_file_1x_avif"
            fi
        done
    done
done

# Читаем итоговую статистику из временного файла
if [ -f "$TEMP_STATS" ]; then
    read total_files processed_files skipped_files < "$TEMP_STATS"
    rm "$TEMP_STATS"
fi

echo "Обработка завершена."
echo "Всего найдено файлов для конвертации: $total_files"
echo "Создано AVIF-файлов: $processed_files"
echo "Пропущено (уже существуют): $skipped_files"
