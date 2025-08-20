#!/usr/bin/env bash
set -euo pipefail

# MA Tools: Interactive Docker-powered utility launcher
# - Normalize article/file names (snake_case) and update toc.json
# - Validate toc.json and referenced files
# - Convert images to AVIF
#
# Requirements on host: docker

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# Script resides in src/game-lore-library, so repo root is two levels up.
# Prefer git (if inside a repo), otherwise fallback to ../../
if git -C "$SCRIPT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
  REPO_ROOT="$(git -C "$SCRIPT_DIR" rev-parse --show-toplevel)"
else
  REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"
fi
GL_DIR="$SCRIPT_DIR"

# Colors
BOLD='\033[1m'
NC='\033[0m'

need_docker() {
  if ! command -v docker >/dev/null 2>&1; then
    echo "Docker is required but not found. Please install Docker." >&2
    exit 1
  fi
}

build_if_missing() {
  local image_tag="$1" dockerfile_path="$2" context_path="$3"
  if ! docker image inspect "$image_tag" >/dev/null 2>&1; then
    echo -e "${BOLD}Building image:${NC} $image_tag (Dockerfile: $dockerfile_path)"
    docker build -t "$image_tag" -f "$dockerfile_path" "$context_path"
  fi
}

ask_environment() {
  local default="$1"; local allow_both="${2:-false}"
  local env
  while true; do
    if [[ "$allow_both" == "true" ]]; then
      read -r -p "Choose environment [stage|production|both] (default: $default): " env || true
      env=${env:-$default}
      case "$env" in stage|production|both) echo "$env"; return 0;; esac
    else
      read -r -p "Choose environment [stage|production] (default: $default): " env || true
      env=${env:-$default}
      case "$env" in stage|production) echo "$env"; return 0;; esac
    fi
    echo "Invalid value. Try again."
  done
}

run_normalize() {
  local image_tag="ma-gl-normalize"
  build_if_missing "$image_tag" "$GL_DIR/Dockerfile.normalize" "$GL_DIR"
  echo -e "${BOLD}Running normalize...${NC}"
  docker run --rm -it \
    -v "$REPO_ROOT:/work" -w /work \
    "$image_tag" bash -lc 'bash src/game-lore-library/normalize_stage_article_names.sh && git status -s || true'
}

run_validate() {
  local image_tag="ma-gl-validator"
  build_if_missing "$image_tag" "$GL_DIR/Dockerfile.validator" "$GL_DIR"
  local env; env=$(ask_environment "both" true)
  local verbose_flag=""
  read -r -p "Verbose output? [y/N]: " ans || true
  case "$ans" in
    y|Y|yes|YES|Yes) verbose_flag="-v" ;;
  esac
  echo -e "${BOLD}Running toc validator...${NC} (env=$env)"
  # Mount repo GL dir to /app so validator sees /app/{stage,production}
  docker run --rm -it \
    -v "$GL_DIR:/app" \
    "$image_tag" -e "$env" $verbose_flag
}

run_convert_avif() {
  local image_tag="ma-gl-avif"
  # Reuse existing Dockerfile (ubuntu with imagemagick & avif tools)
  build_if_missing "$image_tag" "$GL_DIR/Dockerfile" "$GL_DIR"
  local env; env=$(ask_environment "stage" false)
  echo -e "${BOLD}Running AVIF conversion...${NC} (env=$env)"
  # Mount GL dir to /app, script detects Docker and reads /app/$ENV/articles
  docker run --rm -it \
    -v "$GL_DIR:/app" \
    "$image_tag" -e "$env"
}

run_check_links() {
  local image_tag="ma-gl-links"
  build_if_missing "$image_tag" "$GL_DIR/Dockerfile.links" "$GL_DIR"
  local env; env=$(ask_environment "both" true)
  local verbose_flag=""
  local fix_flag=""
  read -r -p "Verbose output? [y/N]: " ans || true
  case "$ans" in
    y|Y|yes|YES|Yes) verbose_flag="-v" ;;
  esac
  read -r -p "Apply auto-fixes (rename image->images, rewrite links)? [y/N]: " ans || true
  case "$ans" in
    y|Y|yes|YES|Yes) fix_flag="-f" ;;
  esac
  echo -e "${BOLD}Running markdown links validator...${NC} (env=$env)"
  docker run --rm -it \
    -v "$GL_DIR:/app" \
    --entrypoint bash \
    "$image_tag" -lc "bash /app/check_md_links.sh -e $env ${verbose_flag} ${fix_flag}"
}

main_menu() {
  need_docker
  while true; do
    echo
    echo -e "${BOLD}MA Tools${NC} (repo: $REPO_ROOT)"
    echo "1) Normalize article/file names (snake_case)"
    echo "2) Validate toc.json and files"
    echo "3) Convert images to AVIF"
    echo "4) Validate markdown links"
    echo "q) Quit"
    read -r -p "Choose an option: " choice || true
    case "$choice" in
      1) run_normalize ;;
      2) run_validate ;;
      3) run_convert_avif ;;
      4) run_check_links ;;
      q|Q) exit 0 ;;
      *) echo "Unknown option" ;;
    esac
  done
}

main_menu
