#!/usr/bin/env bash
# Normalize Game Lore Library stage article names to latin lowercase snake_case and update toc.json.
# - No Python/jq required. Uses bash + awk + sed available on macOS.
# Usage: bash scripts/normalize_stage_article_names.sh

set -euo pipefail

# Resolve repo root based on script location to be independent of CWD
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/../.." && pwd)"

BASE="$REPO_ROOT/src/game-lore-library/stage"
ART="$BASE/articles"
TOC="$BASE/toc.json"
# Portable mktemp (works on macOS and GNU): put file in $TMPDIR or /tmp, with template
_TMPDIR="${TMPDIR:-/tmp}"
MAPPING_FILE="$(mktemp -p "$_TMPDIR" ma_norm_map.XXXXXX)"
trap 'rm -f "$MAPPING_FILE"' EXIT

# Detect GNU sed for portable in-place edits
SED_INPLACE_GNU=false
if sed --version >/dev/null 2>&1; then
  SED_INPLACE_GNU=true
fi
sed_inplace() {
  # usage: sed_inplace 's/old/new/g' file
  if $SED_INPLACE_GNU; then
    sed -i -e "$1" "$2"
  else
    sed -i '' -e "$1" "$2"
  fi
}

backup() {
  if [[ -f "$TOC" && ! -f "$TOC.bak" ]]; then
    cp "$TOC" "$TOC.bak"
    echo "Backup created: $TOC.bak"
  fi
}

# Transliterate Cyrillic to Latin and slugify to snake_case
slugify() {
  # stdin -> stdout
  awk '
    BEGIN{
      map["А"]="A";map["а"]="a";map["Б"]="B";map["б"]="b";map["В"]="V";map["в"]="v";map["Г"]="G";map["г"]="g";map["Д"]="D";map["д"]="d";
      map["Е"]="E";map["е"]="e";map["Ё"]="E";map["ё"]="e";map["Ж"]="Zh";map["ж"]="zh";map["З"]="Z";map["з"]="z";map["И"]="I";map["и"]="i";
      map["Й"]="Y";map["й"]="y";map["К"]="K";map["к"]="k";map["Л"]="L";map["л"]="l";map["М"]="M";map["м"]="m";map["Н"]="N";map["н"]="n";
      map["О"]="O";map["о"]="o";map["П"]="P";map["п"]="p";map["Р"]="R";map["р"]="r";map["С"]="S";map["с"]="s";map["Т"]="T";map["т"]="t";
      map["У"]="U";map["у"]="u";map["Ф"]="F";map["ф"]="f";map["Х"]="Kh";map["х"]="kh";map["Ц"]="Ts";map["ц"]="ts";map["Ч"]="Ch";map["ч"]="ch";
      map["Ш"]="Sh";map["ш"]="sh";map["Щ"]="Shch";map["щ"]="shch";map["Ъ"]="";map["ъ"]="";map["Ы"]="Y";map["ы"]="y";map["Ь"]="";map["ь"]="";
      map["Э"]="E";map["э"]="e";map["Ю"]="Yu";map["ю"]="yu";map["Я"]="Ya";map["я"]="ya";
    }
    {
      out="";
      n=split($0, arr, "");
      for(i=1;i<=n;i++){c=arr[i]; if(c in map){out=out map[c]} else {out=out c}}
      # to lower (ASCII)
      clow=tolower(out);
      # replace non-alnum with underscores
      gsub(/[^A-Za-z0-9]+/, "_", clow);
      # collapse underscores and trim
      gsub(/_+/, "_", clow);
      sub(/^_+/, "", clow); sub(/_+$/, "", clow);
      print clow;
    }
  '
}

normalize_name() {
  local name="$1"
  case "$name" in
    *_ru.md|*_en.md)
      local base="${name%_*}" # up to last underscore before lang
      local lang="${name##*_}" # like ru.md or en.md
      printf "%s_%s\n" "$(printf "%s" "$base" | slugify)" "$lang"
      ;;
    *.*)
      local stem="${name%%.*}"; local ext="${name##*.}"; local ext_lc
      ext_lc="$(printf "%s" "$ext" | tr 'A-Z' 'a-z')"
      printf "%s.%s\n" "$(printf "%s" "$stem" | slugify)" "$ext_lc"
      ;;
    *)
      printf "%s\n" "$(printf "%s" "$name" | slugify)"
      ;;
  esac
}

rename_path() {
  # $1 src abs, $2 dst abs
  local src="$1" dst="$2"
  [[ "$src" == "$dst" ]] && return 0
  local tmp="${dst}__tmp__"
  if [[ -e "$tmp" ]]; then
    # ensure unique tmp
    local i=2
    while [[ -e "${dst}__tmp__${i}" ]]; do i=$((i+1)); done
    tmp="${dst}__tmp__${i}"
  fi
  mv "$src" "$tmp"
  mv "$tmp" "$dst"
}

normalize_articles() {
  # Rename top-level directories
  find "$ART" -mindepth 1 -maxdepth 1 -type d -print0 | while IFS= read -r -d '' dir; do
    local dname; dname="$(basename "$dir")"
    local ndir; ndir="$(normalize_name "$dname")"
    local dst="$ART/$ndir"
    if [[ "$dir" != "$dst" ]]; then
      [[ -e "$dst" ]] && dst="${dst}_2"
      echo "Dir: $dname -> $(basename "$dst")"
      rename_path "$dir" "$dst"
      dir="$dst"
    fi
    # files inside
    find "$dir" -mindepth 1 -maxdepth 1 -type f -print0 | while IFS= read -r -d '' f; do
      local fname nfname dstf
      fname="$(basename "$f")"
      nfname="$(normalize_name "$fname")"
      dstf="$(dirname "$f")/$nfname"
      if [[ "$f" != "$dstf" ]]; then
        echo "File: $fname -> $nfname"
        # track mapping only for markdown relative to repo root
        if [[ "$f" == *.md ]]; then
          local rel_old rel_new
          rel_old="${f#"$REPO_ROOT/"}"
          rename_path "$f" "$dstf"
          rel_new="${dstf#"$REPO_ROOT/"}"
          printf "%s -> %s\n" "$rel_old" "$rel_new" >> "$MAPPING_FILE"
        else
          rename_path "$f" "$dstf"
        fi
      fi
    done
  done
}

update_toc() {
  [[ -f "$TOC" ]] || { echo "No $TOC"; return; }
  backup
  if [[ -s "$MAPPING_FILE" ]]; then
    while IFS= read -r line; do
      # line format: old -> new
      old="${line%% -> *}"; new="${line##* -> }"
      # convert to toc-relative by stripping prefix up to articles/
      old_rel="${old#*src/game-lore-library/stage/}"
      new_rel="${new#*src/game-lore-library/stage/}"
      # apply replacement in-place (macOS sed)
      old_esc=$(printf '%s' "$old_rel" | sed -e 's/[\&/]/\\&/g')
      new_esc=$(printf '%s' "$new_rel" | sed -e 's/[\&/]/\\&/g')
      sed_inplace "s/$old_esc/$new_esc/g" "$TOC"
    done < "$MAPPING_FILE"
    echo "toc.json updated"
  else
    echo "No markdown renames recorded; toc.json left unchanged"
  fi
}

main() {
  [[ -d "$ART" ]] || { echo "Not found: $ART"; exit 1; }
  normalize_articles
  update_toc
  # Stage changes in git if available
  git add -A "$BASE" 2>/dev/null || true
  echo "Done."
}

main "$@"
