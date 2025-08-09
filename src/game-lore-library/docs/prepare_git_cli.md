# Подготовка: Git из терминала (CLI)

[← Назад к README](../README.md)

Этот раздел для тех, кто готов пользоваться терминалом. Здесь — установка Git, первичная настройка, клонирование, коммиты и отправка изменений, а также способы аутентификации (HTTPS + PAT и SSH).

## Установка Git

### Windows
1. Скачать: https://git-scm.com/download/win
2. Установить (оставьте настройки по умолчанию)
3. Появится «Git Bash» — удобная командная строка для Git

### macOS
- Вариант 1 (проще): Xcode Command Line Tools
  ```bash
  xcode-select --install
  ```
- Вариант 2: Homebrew
  ```bash
  brew install git
  ```
- Вариант 3: официальный сайт — https://git-scm.com/download/mac

### Linux
- Ubuntu/Debian:
  ```bash
  sudo apt-get update && sudo apt-get install -y git
  ```
- Fedora:
  ```bash
  sudo dnf install -y git
  ```
- Arch:
  ```bash
  sudo pacman -S git
  ```

## Первичная настройка (однократно)

```bash
git config --global user.name "Ваше Имя"
git config --global user.email "you@example.com"
```

Совет: если не уверены с SSH — используйте HTTPS при клонировании (проще).

## Клонирование репозитория

```bash
git clone https://github.com/magicalchemy/static-content.git
cd static-content/src/game-lore-library
```

Откройте папку `static-content/src/game-lore-library` в выбранном редакторе (см. «[Выбор редактора](prepare_editors.md)»).

## Коммит и отправка изменений

```bash
git status
# Добавьте новые/изменённые файлы
git add src/game-lore-library/stage
# Коммит с сообщением
git commit -m "Добавлена новая статья: ..."
# Отправка на GitHub
git push origin main
```

Если что-то не получилось — сообщите команде, мы поможем.

## Аутентификация и доступ к GitHub

Если нет доступа к репозиторию — обратитесь к технарям, они выдадут права и подскажут подходящий способ подключения.

### Вариант A — HTTPS + Personal Access Token (просто)
1. GitHub → профиль → Settings → Developer settings → Personal access tokens → Tokens (classic)
2. Создайте токен с правами `repo`
3. При `git push`:
   - Username: ваш логин GitHub
   - Password: вставьте сгенерированный Token (PAT)
4. Данные будут сохранены менеджером учётных данных.

### Вариант B — SSH‑ключи (чуть сложнее, но удобно)
1. Сгенерируйте ключ:
   ```bash
   ssh-keygen -t ed25519 -C "you@example.com"
   ```
2. Добавьте ключ в агент:
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add ~/.ssh/id_ed25519
   ```
   Windows (Git Bash):
   ```bash
   eval "$(ssh-agent -s)"
   ssh-add /c/Users/<USER>/.ssh/id_ed25519
   ```
3. Добавьте публичный ключ на GitHub: Settings → SSH and GPG keys → New SSH key
   ```bash
   cat ~/.ssh/id_ed25519.pub
   ```
4. (Опционально) `~/.ssh/config`:
   ```
   Host github.com
     HostName github.com
     User git
     IdentityFile ~/.ssh/id_ed25519
     AddKeysToAgent yes
   ```
5. Проверка и клонирование по SSH:
   ```bash
   ssh -T git@github.com
   git clone git@github.com:magicalchemy/static-content.git
   ```

Если возникли сложности с ключами/доступом — обратитесь к технарям.
