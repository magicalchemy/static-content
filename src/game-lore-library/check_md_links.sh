#!/usr/bin/env bash
set -uo pipefail

# Check Markdown links and anchors across game-lore-library content
# - Validates relative links exist
# - Ensures article filenames use snake_case and correct language suffix (_ru.md/_en.md)
# - Validates anchors (#id) exist in target file and are in [a-z0-9-]+
# - Enforces images are stored under "images/" directory (not "image/")
# - Allows absolute site links starting with /
# - Skips http(s) links
#
# Usage:
#   check_md_links.sh -e stage|production|both [-v] [-f]

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
GL_DIR="$SCRIPT_DIR"

ENVIRONMENT="stage"
VERBOSE=false
FIX=false

usage() {
  echo "Usage: $0 -e stage|production|both [-v] [-f]" >&2
}

while getopts ":e:vf" opt; do
  case $opt in
    e) ENVIRONMENT="$OPTARG" ;;
    v) VERBOSE=true ;;
    f) FIX=true ;;
    *) usage; exit 2 ;;
  esac
done

if [[ "$ENVIRONMENT" != "stage" && "$ENVIRONMENT" != "production" && "$ENVIRONMENT" != "both" ]]; then
  usage; exit 2
fi

logv() { $VERBOSE && echo "$*" || true; }

# Styling for readable output
BOLD='\033[1m'
NC='\033[0m'

ERRORS=0
FILES_WITH_ISSUES=0

declare -a ENVS
if [[ "$ENVIRONMENT" == "both" ]]; then
  ENVS=("stage" "production")
else
  ENVS=("$ENVIRONMENT")
fi

# Extract links from a markdown file (both links and images)
# Outputs: link\tlineno\ttype (link|image)
extract_links() {
  local file="$1"
  # Use awk to track line numbers and extract () targets; capture both ![]() and []()
  awk '
    {
      line=$0; n=split(line, parts, /\]\(/);
      # simple scan for patterns [..](..)
    }
  ' "$file" 2>/dev/null | true
}

# More robust extraction with grep -nPo (GNU grep present in Ubuntu)
extract_links_grep() {
  local file="$1"
  # Capture both link and image; we will detect image by preceding '!'
  # Output: lineno\tfullmatch\ttarget
  (grep -nPo '!?(\[[^\]]*\]\([^\)]+\))' "$file" || true) | while IFS=: read -r lineno match; do
    # get target inside (...)
    target="$(sed -E 's/.*\(([^\)]+)\).*/\1/' <<<"$match")"
    if [[ "$match" == \!* ]]; then type=image; else type=link; fi
    printf "%s\t%s\t%s\n" "$lineno" "$type" "$target"
  done
}

# Collect defined anchors in a markdown file: ids from {...} after headers
collect_anchors() {
  local file="$1"
  # Match patterns like: ## Title {#id}
  grep -oP '\{#([a-z0-9-]+)\}' "$file" | sed -E 's/^.*#([a-z0-9-]+).*$/\1/' | sort -u || true
}

is_snake_case_md() {
  local name="$1"
  [[ "$name" =~ ^[a-z0-9_]+(\_(ru|en))?\.md$ ]]
}

lang_suffix_of() {
  local name="$1"
  if [[ "$name" =~ _ru\.md$ ]]; then echo ru; return 0; fi
  if [[ "$name" =~ _en\.md$ ]]; then echo en; return 0; fi
  echo unknown
}

check_file_links() {
  local env_root="$1" file="$2"
  local file_dir; file_dir="$(dirname "$file")"
  local rel_from_env; rel_from_env="${file#"$env_root/"}"
  local file_lang; file_lang="$(lang_suffix_of "$(basename "$file")")"
  # Collect errors to print them grouped by file at the end
  declare -a file_errors=()

  # Optional structural fix: rename single 'image' directory to 'images' in the same article folder
  if $FIX; then
    if [[ -d "$file_dir/image" && ! -d "$file_dir/images" ]]; then
      mv "$file_dir/image" "$file_dir/images" 2>/dev/null || true
      logv "Renamed directory: ${rel_from_env%/*}/image -> images"
    fi
  fi

  while IFS=$'\t' read -r lineno type target; do
    # Trim surrounding spaces
    target="${target%%[[:space:]]*}"
    target="${target## }"

    # Skip empty
    [[ -z "$target" ]] && continue

    # Skip http(s)
    if [[ "$target" =~ ^https?:// ]]; then
      continue
    fi

    # Site absolute paths
    if [[ "$target" =~ ^/ ]]; then
      # Must not contain spaces
      if [[ "$target" =~ [[:space:]] ]]; then
        file_errors+=("$lineno|absolute site link contains spaces: $target")
        ((ERRORS++))
      fi
      continue
    fi

    # Split anchor if present
    local path_only="$target" anchor=""
    if [[ "$target" == *#* ]]; then
      path_only="${target%%#*}"
      anchor="${target#*#}"
    fi

    # Handle pure anchor links (e.g. "#section") as anchors within the same file
    if [[ -z "$path_only" && -n "$anchor" ]]; then
      # validate anchor format and existence in current file
      local norm_anchor="$anchor"
      if [[ ! "$anchor" =~ ^[a-z0-9-]+$ ]]; then
        # try normalize: lowercase and replace spaces/underscores with '-'
        norm_anchor="$(echo "$anchor" | tr 'A-Z' 'a-z' | sed -E 's/[ _]+/-/g')"
        if collect_anchors "$file" | grep -qx "$norm_anchor"; then
          if $FIX; then
            # rewrite #Anchor to #anchor-kebab
            sed -i "${lineno}s|#${anchor}|#${norm_anchor}|" "$file"
            logv "Rewrote anchor link to: #$norm_anchor"
            continue
          else
            file_errors+=("$lineno|invalid anchor format (allowed [a-z0-9-]+): #$anchor (did you mean #$norm_anchor?)")
            ((ERRORS++))
            continue
          fi
        else
          file_errors+=("$lineno|invalid anchor format (allowed [a-z0-9-]+): #$anchor")
          ((ERRORS++))
          # still check existence to provide more context
          if ! collect_anchors "$file" | grep -qx "$anchor"; then
            file_errors+=("$lineno|anchor not found in target: $(basename "$file")#$anchor")
            ((ERRORS++))
          fi
          continue
        fi
      else
        if ! collect_anchors "$file" | grep -qx "$anchor"; then
          file_errors+=("$lineno|anchor not found in target: $(basename "$file")#$anchor")
          ((ERRORS++))
        fi
      fi
      # No further path checks needed for pure-anchor links
      continue
    fi

    # Resolve relative path
    local abs_target
    abs_target="$(cd "$file_dir" && realpath -m "$path_only" 2>/dev/null || true)"
    if [[ -z "$abs_target" || ! -e "$abs_target" ]]; then
      # Try to auto-fix common cases before reporting an error
      local fixed_link=""

      # 1) Image bare filename in same directory -> images/<name>
      if [[ "$type" == "image" && "$path_only" != */* ]]; then
        if [[ -f "$file_dir/images/$path_only" ]]; then
          fixed_link="images/$path_only"
        elif [[ -f "$file_dir/image/$path_only" ]]; then
          fixed_link="images/$path_only"
        elif [[ -f "$file_dir/$path_only" ]]; then
          # if current file is inside an 'image' dir, try parent '../images/<name>'
          if [[ "$file_dir" == */image ]]; then
            if [[ -f "${file_dir%/image}/images/$path_only" ]]; then
              fixed_link="../images/$path_only"
            elif [[ -f "${file_dir%/image}/image/$path_only" ]]; then
              fixed_link="../images/$path_only"
            fi
          fi
        fi
      fi

      # 2) Project absolute path -> make relative
      #    Supported prefixes:
      #    - src/game-lore-library/...
      #    - static-content/src/game-lore-library/...
      #    - paths already under $GL_DIR (rare)
      if [[ -z "$fixed_link" ]]; then
        local candidate=""
        if [[ "$path_only" =~ ^src/game-lore-library/ ]]; then
          candidate="$GL_DIR/${path_only#src/game-lore-library/}"
        elif [[ "$path_only" =~ ^static-content/src/game-lore-library/ ]]; then
          candidate="$GL_DIR/${path_only#static-content/src/game-lore-library/}"
        elif [[ "$path_only" == $GL_DIR/* ]]; then
          candidate="$path_only"
        fi
        if [[ -n "$candidate" && -e "$candidate" ]]; then
          if relp=$(realpath --relative-to="$file_dir" "$candidate" 2>/dev/null); then
            fixed_link="$relp"
          else
            fixed_link="$candidate"
          fi
        fi
      fi

      if [[ -n "$fixed_link" ]]; then
        if $FIX; then
          # Apply in-place rewrite for this specific line
          sed -i "${lineno}s|([[:space:]]*${target//\//\/}[[:space:]]*)|(${fixed_link}${anchor:+#}$anchor)|" "$file"
          logv "Rewrote link to: $fixed_link${anchor:+#}$anchor"
          continue
        else
          file_errors+=("$lineno|target not found: $target (did you mean: $fixed_link?)")
          ((ERRORS++))
          continue
        fi
      fi

      # Could not auto-fix
      # 3) If missing .md target: search by basename across env and rewrite
      if [[ "$path_only" =~ \.md$ ]]; then
        local base_md
        base_md="$(basename "$path_only")"
        local found
        IFS=$'\n' read -rd '' -a found < <(find "$env_root" -type f -name "$base_md" 2>/dev/null && printf '\0') || true
        # fallback: case-insensitive search
        if (( ${#found[@]} == 0 )); then
          IFS=$'\n' read -rd '' -a found < <(find "$env_root" -type f -iname "$base_md" 2>/dev/null && printf '\0') || true
        fi
        if (( ${#found[@]} == 1 )); then
          local candidate="${found[0]}"
          if relp=$(realpath --relative-to="$file_dir" "$candidate" 2>/dev/null); then
            if $FIX; then
              sed -i "${lineno}s|([[:space:]]*${target//\//\/}[[:space:]]*)|(${relp}${anchor:+#}$anchor)|" "$file"
              logv "Rewrote MD link to found target: $relp${anchor:+#}$anchor"
              continue
            else
              file_errors+=("$lineno|target not found: $target (did you mean: $relp?)")
              ((ERRORS++))
              continue
            fi
          fi
        fi
      fi

      file_errors+=("$lineno|target not found: $target (resolved from $path_only)")
      ((ERRORS++))
      continue
    fi

    # If it's a markdown file, enforce snake_case and language suffix
    if [[ "$abs_target" =~ \.md$ ]]; then
      local base; base="$(basename "$abs_target")"
      if ! is_snake_case_md "$base"; then
        file_errors+=("$lineno|markdown filename not snake_case with optional _ru/_en: $base (link: $target)")
        ((ERRORS++))
      fi
      # Require explicit language suffix for article files
      local lang; lang="$(lang_suffix_of "$base")"
      if [[ "$lang" == "unknown" ]]; then
        file_errors+=("$lineno|markdown link must point to _ru.md or _en.md file: $base (link: $target)")
        ((ERRORS++))
      fi
      # If anchor present, validate exists and format
      if [[ -n "$anchor" ]]; then
        local norm_anchor="$anchor"
        if [[ ! "$anchor" =~ ^[a-z0-9-]+$ ]]; then
          norm_anchor="$(echo "$anchor" | tr 'A-Z' 'a-z' | sed -E 's/[ _]+/-/g')"
          if collect_anchors "$abs_target" | grep -qx "$norm_anchor"; then
            if $FIX; then
              sed -i "${lineno}s|#${anchor}|#${norm_anchor}|" "$file"
              logv "Rewrote anchor link to: #$norm_anchor"
            else
              file_errors+=("$lineno|invalid anchor format (allowed [a-z0-9-]+): #$anchor (did you mean #$norm_anchor?)")
              ((ERRORS++))
            fi
          else
            file_errors+=("$lineno|invalid anchor format (allowed [a-z0-9-]+): #$anchor")
            ((ERRORS++))
            if ! collect_anchors "$abs_target" | grep -qx "$anchor"; then
              file_errors+=("$lineno|anchor not found in target: $base#$anchor")
              ((ERRORS++))
            fi
          fi
        else
          # Check anchor exists in target file
          if ! collect_anchors "$abs_target" | grep -qx "$anchor"; then
            file_errors+=("$lineno|anchor not found in target: $base#$anchor")
            ((ERRORS++))
          fi
        fi
      fi
    else
      # Non-md (e.g., images). Additional rules for assets
      local bname; bname="$(basename "$abs_target")"
      if [[ "$bname" =~ [[:space:]] ]]; then
        file_errors+=("$lineno|filename contains spaces: $bname (link: $target)")
        ((ERRORS++))
      fi

      # Enforce images under images/ directory
      local is_image_ext=false
      if [[ "$bname" =~ \.(png|jpg|jpeg|gif|webp|avif|svg)$ ]]; then is_image_ext=true; fi
      if $is_image_ext; then
        # Normalize target path for checks (relative string as in link)
        local tpath="$path_only"
        # Enforce retina-like naming pattern: *.2x.<ext>
        if [[ ! "$bname" =~ \.2x\.(png|jpg|jpeg|gif|webp|avif|svg)$ ]]; then
          # try fix '.2x..' -> '.2x.'
          local tfix="${tpath//.2x../.2x.}"
          if [[ "$tfix" != "$tpath" ]]; then
            local abs_src abs_dst
            abs_src="$(cd "$file_dir" && realpath -m "$tpath" 2>/dev/null || true)"
            abs_dst="$(cd "$file_dir" && realpath -m "$tfix" 2>/dev/null || true)"
            if $FIX; then
              # If destination file missing but source exists, rename file on disk
              if [[ -e "$abs_src" && ! -e "$abs_dst" ]]; then
                mkdir -p "$(dirname "$abs_dst")" || true
                mv "$abs_src" "$abs_dst" 2>/dev/null && logv "Renamed file: ${tpath##*/} -> ${tfix##*/}"
              fi
              sed -i "${lineno}s|(${tpath})|(${tfix})|" "$file"
              logv "Rewrote image filename to: $tfix"
            else
              file_errors+=("$lineno|image filename must follow *.2x.<ext> pattern: $bname (did you mean: ${tfix##*/}?)")
              ((ERRORS++))
            fi
          else
            file_errors+=("$lineno|image filename must follow *.2x.<ext> pattern: $bname (link: $tpath)")
            ((ERRORS++))
          fi
        fi
        if [[ "$tpath" != */* ]]; then
          # Bare filename, suggest/auto-fix to images/<name>
          file_errors+=("$lineno|image path must be under images/: $tpath")
          ((ERRORS++))
          if $FIX; then
            local guess
            if [[ -f "$file_dir/images/$tpath" ]]; then
              guess="images/$tpath"
            elif [[ -f "$file_dir/image/$tpath" ]]; then
              guess="images/$tpath"
            elif [[ -f "$file_dir/$tpath" && "$file_dir" == */image ]]; then
              # migrate assets from current 'image' folder to sibling '../images'
              local src="$file_dir/$tpath"
              local dst_dir="${file_dir%/image}/images"
              mkdir -p "$dst_dir" && mv "$src" "$dst_dir/" 2>/dev/null && logv "Moved asset to: $dst_dir/${tpath##*/}"
              if [[ -f "$dst_dir/${tpath##*/}" ]]; then
                guess="../images/${tpath##*/}"
              fi
            fi
            if [[ -n "${guess:-}" ]]; then
              sed -i "${lineno}s|([[:space:]]*${target//\//\/}[[:space:]]*)|(${guess})|" "$file"
              logv "Rewrote image link to: $guess"
            fi
          fi
        else
          # Has directory component
          if [[ "$tpath" == image/* || "$tpath" == */image/* ]]; then
            file_errors+=("$lineno|use 'images/' directory, not 'image/': $tpath")
            ((ERRORS++))
            if $FIX; then
              local fixed="${tpath//\/image\//\/images\/}"
              fixed="${fixed/#image\//images/}"
              sed -i "${lineno}s|([[:space:]]*${target//\//\/}[[:space:]]*)|(${fixed}${anchor:+#}$anchor)|" "$file"
              logv "Rewrote image link to: $fixed"
            fi
          elif [[ "$tpath" != images/* && "$tpath" != */images/* ]]; then
            file_errors+=("$lineno|image path must be under images/: $tpath")
            ((ERRORS++))
          fi
        fi
      fi
    fi
  done < <(extract_links_grep "$file")

  # Print grouped errors for this file
  if ((${#file_errors[@]} > 0)); then
    ((FILES_WITH_ISSUES++))
    echo -e "${BOLD}File: ${rel_from_env}${NC}"
    for e in "${file_errors[@]}"; do
      IFS='|' read -r l m <<<"$e"
      echo "  - L${l}: ${m}"
    done
  fi
}

run_for_env() {
  local env="$1"
  local root="$GL_DIR/$env"
  logv "Scanning environment: $env ($root)"
  # Find all .md under env
  while IFS= read -r -d '' md; do
    logv "Checking: ${md#"$root/"}"
    check_file_links "$root" "$md"
  done < <(find "$root" -type f -name "*.md" -print0)
}

for e in "${ENVS[@]}"; do
  run_for_env "$e"
done

if (( ERRORS > 0 )); then
  echo -e "${BOLD}Summary:${NC} $ERRORS issues in $FILES_WITH_ISSUES files." >&2
  exit 1
else
  echo "All markdown links look good."
fi
