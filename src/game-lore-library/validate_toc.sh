#!/bin/bash

# Скрипт для валидации toc.json и проверки наличия всех указанных файлов
# Автор: Cascade, 2025-08-09

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
NC='\033[0m' # No Color

# Счетчики для статистики
total_entries=0
missing_files=0
invalid_entries=0
warnings_count=0

# Массивы для группировки ошибок и предупреждений
missing_toc_files=()
missing_md_files=()
invalid_json_errors=()
structure_errors=()
format_errors=()
warnings_no_en=()
warnings_no_ru=()
warnings_same_file=()

# Параметры по умолчанию
ENVIRONMENT="both"
VERBOSE=false

# Обработка параметров командной строки
while [[ "$#" -gt 0 ]]; do
    case $1 in
        -e|--environment) ENVIRONMENT="$2"; shift ;;
        -v|--verbose) VERBOSE=true ;;
        -h|--help) 
            echo "Использование: $0 [-e|--environment {stage|production|both}] [-v|--verbose]"
            echo "  -e, --environment   Указывает окружение для проверки (stage, production или both)"
            echo "  -v, --verbose       Подробный вывод с дополнительной информацией"
            echo "  -h, --help          Показывает эту справку"
            exit 0
            ;;
        *) echo "Неизвестный параметр: $1"; exit 1 ;;
    esac
    shift
done

# Проверка корректности окружения
if [[ "$ENVIRONMENT" != "stage" && "$ENVIRONMENT" != "production" && "$ENVIRONMENT" != "both" ]]; then
    echo -e "${RED}Ошибка: окружение должно быть 'stage', 'production' или 'both'.${NC}"
    exit 1
fi

# Директории для проверки
# Проверка, запущен ли скрипт в Docker
if [ -f "/.dockerenv" ]; then
    echo -e "${YELLOW}Запуск в режиме Docker${NC}"
    SCRIPT_DIR="/app"
else
    SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

STAGE_DIR="$SCRIPT_DIR/stage"
PRODUCTION_DIR="$SCRIPT_DIR/production"

# Функции для добавления ошибок по категориям
add_missing_toc() {
    local env=$1
    local message=$2
    missing_toc_files+=("[$env] $message")
}

add_missing_md() {
    local env=$1
    local message=$2
    missing_md_files+=("[$env] $message")
    ((missing_files++))
}

add_invalid_json() {
    local env=$1
    local message=$2
    invalid_json_errors+=("[$env] $message")
}

add_structure_error() {
    local env=$1
    local message=$2
    structure_errors+=("[$env] $message")
    ((invalid_entries++))
}

add_format_error() {
    local env=$1
    local message=$2
    local location=$3
    format_errors+=("[$env] $message в $location")
    ((invalid_entries++))
}

# Функции для добавления предупреждений по категориям
add_warning_no_en() {
    local env=$1
    local title=$2

    warnings_no_en+=("[$env] Статья '$title' не имеет английской версии")
    ((warnings_count++))
}

add_warning_no_ru() {
    local env=$1
    local title=$2
    warnings_no_ru+=("[$env] Статья '$title' не имеет русской версии")
    ((warnings_count++))
}

add_warning_same_file() {
    local env=$1
    local title=$2
    local file=$3
    warnings_same_file+=("[$env] Статья '$title' имеет одинаковый путь для русской и английской версий: $file")
    ((warnings_count++))
}

# Функция для проверки существования файла
check_file_exists() {
    local env_dir=$1
    local file_path=$2
    local env_name=$3
    
    if [[ ! -f "$env_dir/$file_path" ]]; then
        add_missing_md "$env_name" "Файл $file_path не существует"
        return 1
    fi
    return 0
}

# Функция для валидации toc.json и проверки файлов
validate_toc() {
    local env_dir=$1
    local env_name=$2
    local toc_file="$env_dir/toc.json"
    
    echo -e "\n${YELLOW}Проверка окружения $env_name...${NC}"
    
    # Проверка наличия toc.json
    if [[ ! -f "$toc_file" ]]; then
        add_missing_toc "$env_name" "Файл toc.json отсутствует"
        return 1
    fi
    
    # Проверка валидности JSON
    if ! jq empty "$toc_file" 2>/dev/null; then
        add_invalid_json "$env_name" "Файл $toc_file не является валидным JSON"
        return 1
    fi
    
    # Проверка основной структуры
    if ! jq -e '.WIKI != null and .LORE != null' "$toc_file" >/dev/null; then
        add_structure_error "$env_name" "Файл toc.json должен содержать ключи WIKI и LORE"
        return 1
    fi
    
    # Проверка структуры toc.json
    validate_toc_structure "$toc_file" "$env_name"
    
    # Извлечение и проверка всех путей к файлам
    local file_paths=$(jq -r '[.WIKI,.LORE] | .. | objects | select(has("files")) | .files | to_entries[] | .value' "$toc_file")
    
    for file_path in $file_paths; do
        ((total_entries++))
        
        if [[ "$VERBOSE" == "true" ]]; then
            echo "Проверка файла: $file_path"
        fi
        
        check_file_exists "$env_dir" "$file_path" "$env_name"
    done
}

# Функция для проверки структуры toc.json
validate_toc_structure() {
    local toc_file=$1
    local env_name=$2
    
    # Вспомогательная: рекурсивная проверка списка items
    validate_items_recursive() {
        local section=$1
        local category_idx=$2
        local path_prefix=$3
        local length=$(jq -r ".$section[$category_idx].items | length" "$toc_file")

        for j in $(seq 0 $((length-1))); do
            local base_path="$path_prefix.items[$j]"
            local item_title_ru=$(jq -r ".$section[$category_idx].items[$j].title.ru // \"[Без названия]\"" "$toc_file")
            local item_location="$base_path ($item_title_ru)"

            # title.ru/en обязательны
            if ! jq -e ".$section[$category_idx].items[$j].title != null" "$toc_file" >/dev/null; then
                add_structure_error "$env_name" "В секции $item_location отсутствует поле title"
            elif ! jq -e ".$section[$category_idx].items[$j].title.ru != null" "$toc_file" >/dev/null || ! jq -e ".$section[$category_idx].items[$j].title.en != null" "$toc_file" >/dev/null; then
                add_structure_error "$env_name" "В секции $item_location поля title.ru и title.en обязательны"
            fi

            local has_files=$(jq -e ".$section[$category_idx].items[$j].files != null" "$toc_file" >/dev/null; echo $?)
            local has_items=$(jq -e ".$section[$category_idx].items[$j].items != null" "$toc_file" >/dev/null; echo $?)

            if [[ "$has_files" -eq 0 ]]; then
                # Элемент-статья
                local has_ru=false
                local has_en=false
                if jq -e ".$section[$category_idx].items[$j].files.ru != null" "$toc_file" >/dev/null 2>&1; then has_ru=true; fi
                if jq -e ".$section[$category_idx].items[$j].files.en != null" "$toc_file" >/dev/null 2>&1; then has_en=true; fi

                if [[ "$has_ru" == false && "$has_en" == false ]]; then
                    add_structure_error "$env_name" "В секции $item_location отсутствуют файлы для обоих языков"
                fi

                if [[ "$has_ru" == true ]]; then
                    local file_ru=$(jq -r ".$section[$category_idx].items[$j].files.ru" "$toc_file")
                    if [[ ! "$file_ru" =~ ^articles/.+/.+\.md$ ]]; then
                        add_format_error "$env_name" "Неправильный формат пути к файлу ru: $file_ru. Должно быть articles/название_статьи/файл.md" "$item_location"
                    else
                        if [[ "$file_ru" =~ _en\.md$ ]]; then
                            add_format_error "$env_name" "Русская версия ссылается на английский файл: $file_ru" "$item_location"
                        elif [[ ! "$file_ru" =~ _ru\.md$ ]]; then
                            add_format_error "$env_name" "Файл русской версии должен заканчиваться на '_ru.md': $file_ru" "$item_location"
                        fi
                    fi
                else
                    add_warning_no_ru "$env_name" "$item_title_ru"
                fi

                if [[ "$has_en" == true ]]; then
                    local file_en=$(jq -r ".$section[$category_idx].items[$j].files.en" "$toc_file")
                    if [[ ! "$file_en" =~ ^articles/.+/.+\.md$ ]]; then
                        add_format_error "$env_name" "Неправильный формат пути к файлу en: $file_en. Должно быть articles/название_статьи/файл.md" "$item_location"
                    else
                        if [[ "$file_en" =~ _ru\.md$ ]]; then
                            add_format_error "$env_name" "Английская версия ссылается на русский файл: $file_en" "$item_location"
                        elif [[ ! "$file_en" =~ _en\.md$ ]]; then
                            add_format_error "$env_name" "Файл английской версии должен заканчиваться на '_en.md': $file_en" "$item_location"
                        fi
                    fi
                else
                    add_warning_no_en "$env_name" "$item_title_ru"
                fi

                if [[ "$has_ru" == true && "$has_en" == true ]]; then
                    local file_ru=$(jq -r ".$section[$category_idx].items[$j].files.ru" "$toc_file")
                    local file_en=$(jq -r ".$section[$category_idx].items[$j].files.en" "$toc_file")
                    if [[ "$file_ru" == "$file_en" ]]; then
                        add_warning_same_file "$env_name" "$item_title_ru" "$file_ru"
                    fi
                fi
            elif [[ "$has_items" -eq 0 ]]; then
                # Элемент-подкатегория (вложенная категория)
                if ! jq -e ".$section[$category_idx].items[$j].items | type == \"array\"" "$toc_file" >/dev/null; then
                    add_structure_error "$env_name" "В секции $item_location поле items должно быть массивом"
                    continue
                fi
                # Рекурсивная проверка
                validate_items_recursive "$section" "$category_idx" "$base_path"
            else
                # Некорректный элемент: ни files, ни items
                add_structure_error "$env_name" "В секции $item_location должен быть либо блок files (статья), либо items (подкатегория)"
            fi
        done
    }

    # Проверка категорий WIKI и LORE
    for section in "WIKI" "LORE"; do
        if ! jq -e ".$section | type == \"array\"" "$toc_file" >/dev/null; then
            add_structure_error "$env_name" "Секция $section должна быть массивом"
            continue
        fi

        local category_count=$(jq -r ".$section | length" "$toc_file")
        for i in $(seq 0 $((category_count-1))); do
            if ! jq -e ".$section[$i].title != null" "$toc_file" >/dev/null; then
                add_structure_error "$env_name" "В секции $section[$i] отсутствует поле title"
            elif ! jq -e ".$section[$i].title.ru != null" "$toc_file" >/dev/null || ! jq -e ".$section[$i].title.en != null" "$toc_file" >/dev/null; then
                add_structure_error "$env_name" "В секции $section[$i].title должны быть поля ru и en"
            fi

            if ! jq -e ".$section[$i].items != null" "$toc_file" >/dev/null; then
                add_structure_error "$env_name" "В секции $section[$i] отсутствует поле items"
                continue
            fi

            if ! jq -e ".$section[$i].items | type == \"array\"" "$toc_file" >/dev/null; then
                add_structure_error "$env_name" "В секции $section[$i] поле items должно быть массивом"
                continue
            fi

            # Рекурсивная проверка элементов категории (статьи и/или подкатегории)
            validate_items_recursive "$section" "$i" "$section[$i]"
        done
    done
}

# Основная функция
main() {
    echo -e "${YELLOW}Запуск валидации файлов toc.json...${NC}"
    
    # Проверка зависимостей
    if ! command -v jq &> /dev/null; then
        echo -e "${RED}Ошибка: для работы скрипта требуется утилита jq.${NC}"
        echo -e "Установите jq:"
        echo -e "  - macOS: brew install jq"
        echo -e "  - Ubuntu/Debian: sudo apt install jq"
        exit 1
    fi
    
    # Валидация для указанных окружений
    if [[ "$ENVIRONMENT" == "stage" || "$ENVIRONMENT" == "both" ]]; then
        validate_toc "$STAGE_DIR" "stage"
    fi
    
    if [[ "$ENVIRONMENT" == "production" || "$ENVIRONMENT" == "both" ]]; then
        validate_toc "$PRODUCTION_DIR" "production"
    fi
    
    # Подсчет общего количества ошибок и предупреждений
    total_errors=$((${#missing_toc_files[@]} + ${#missing_md_files[@]} + ${#invalid_json_errors[@]} + ${#structure_errors[@]} + ${#format_errors[@]}))
    
    warnings_count=$((${#warnings_no_en[@]} + ${#warnings_no_ru[@]} + ${#warnings_same_file[@]}))
    
    # Вывод результатов
    echo -e "\n${YELLOW}Результаты проверки:${NC}"
    echo -e "Всего проверено записей: $total_entries"
    
    # Вывод ошибок по группам
    if [[ $total_errors -eq 0 ]]; then
        echo -e "${GREEN}Ошибок не найдено!${NC}"
    else
        echo -e "${RED}Найдено ошибок: $total_errors${NC}"
        echo -e "${RED}Отсутствующих файлов toc.json: ${#missing_toc_files[@]}${NC}"
        echo -e "${RED}Отсутствующих MD-файлов: $missing_files${NC}"
        echo -e "${RED}Ошибок JSON: ${#invalid_json_errors[@]}${NC}"
        echo -e "${RED}Ошибок структуры: ${#structure_errors[@]}${NC}"
        echo -e "${RED}Ошибок формата: ${#format_errors[@]}${NC}"
        
        # Вывод отсутствующих toc.json файлов
        if [[ ${#missing_toc_files[@]} -gt 0 ]]; then
            echo -e "\n${YELLOW}Отсутствующие файлы toc.json:${NC}"
            for error in "${missing_toc_files[@]}"; do
                echo -e "${RED}- $error${NC}"
            done
        fi
        
        # Вывод отсутствующих MD-файлов
        if [[ ${#missing_md_files[@]} -gt 0 ]]; then
            echo -e "\n${YELLOW}Отсутствующие MD-файлы:${NC}"
            for error in "${missing_md_files[@]}"; do
                echo -e "${RED}- $error${NC}"
            done
        fi
        
        # Вывод ошибок структуры JSON
        if [[ ${#invalid_json_errors[@]} -gt 0 ]]; then
            echo -e "\n${YELLOW}Ошибки JSON:${NC}"
            for error in "${invalid_json_errors[@]}"; do
                echo -e "${RED}- $error${NC}"
            done
        fi
        
        # Вывод ошибок структуры
        if [[ ${#structure_errors[@]} -gt 0 ]]; then
            echo -e "\n${YELLOW}Ошибки структуры:${NC}"
            for error in "${structure_errors[@]}"; do
                echo -e "${RED}- $error${NC}"
            done
        fi
        
        # Вывод ошибок формата
        if [[ ${#format_errors[@]} -gt 0 ]]; then
            echo -e "\n${YELLOW}Ошибки формата:${NC}"
            for error in "${format_errors[@]}"; do
                echo -e "${RED}- $error${NC}"
            done
        fi
    fi
    
    # Вывод предупреждений по группам
    if [[ $warnings_count -gt 0 ]]; then
        echo -e "\n${YELLOW}Предупреждения: $warnings_count${NC}"
        
        # Вывод предупреждений об отсутствии русских версий
        if [[ ${#warnings_no_ru[@]} -gt 0 ]]; then
            echo -e "\n${YELLOW}Отсутствуют русские версии:${NC}"
            for warning in "${warnings_no_ru[@]}"; do
                echo -e "${YELLOW}- $warning${NC}"
            done
        fi
        
        # Вывод предупреждений об отсутствии английских версий
        if [[ ${#warnings_no_en[@]} -gt 0 ]]; then
            echo -e "\n${YELLOW}Отсутствуют английские версии:${NC}"
            for warning in "${warnings_no_en[@]}"; do
                echo -e "${YELLOW}- $warning${NC}"
            done
        fi
        
        # Вывод предупреждений об одинаковых файлах
        if [[ ${#warnings_same_file[@]} -gt 0 ]]; then
            echo -e "\n${YELLOW}Одинаковые пути для разных языков:${NC}"
            for warning in "${warnings_same_file[@]}"; do
                echo -e "${YELLOW}- $warning${NC}"
            done
        fi
    fi
    
    # Выход с ошибкой, если есть ошибки
    if [[ $total_errors -gt 0 ]]; then
        exit 1
    fi
}

# Запуск скрипта
main
