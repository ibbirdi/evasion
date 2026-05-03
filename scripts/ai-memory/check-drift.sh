#!/usr/bin/env bash
# scripts/ai-memory/check-drift.sh
#
# Comprehensive memory drift report. Run on demand from repo root:
#   bash scripts/ai-memory/check-drift.sh
#
# Detects two drift sources:
#   1. STALE      — a source file listed in `tracks:` was committed AFTER `last_updated:`
#   2. DEAD REFS  — a `tracks:` glob matches no file in the repo
#
# Exits 0 if memory is fresh, 1 otherwise.

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

MEMORY_DIR="docs/ai"
HAS_DRIFT=0
declare -a STALE
declare -a DEAD_REFS

# Cross-platform date → epoch (handles macOS BSD date and GNU date).
date_to_epoch() {
  if epoch=$(date -j -f "%Y-%m-%d" "$1" "+%s" 2>/dev/null); then
    echo "$epoch"; return
  fi
  if epoch=$(date -d "$1" "+%s" 2>/dev/null); then
    echo "$epoch"; return
  fi
  echo ""
}

while IFS= read -r mem; do
  # Skip files without YAML frontmatter (changelog, README).
  head -1 "$mem" | grep -qx '^---$' || continue

  # Capture the frontmatter block (between the first two --- lines).
  fm=$(awk '/^---$/{c++; if(c==2) exit; next} c==1{print}' "$mem")

  last_updated=$(printf '%s\n' "$fm" | grep '^last_updated:' | head -1 | awk '{print $2}')
  [[ -z "$last_updated" ]] && continue

  last_epoch=$(date_to_epoch "$last_updated")
  if [[ -z "$last_epoch" ]]; then
    echo "  warning: cannot parse last_updated='$last_updated' in $mem" >&2
    continue
  fi

  # Extract the `tracks:` list (lines like `  - "..."` or `  - ...` until the next top-level key).
  tracks=$(printf '%s\n' "$fm" | awk '
    /^tracks:/        { flag=1; next }
    flag && /^[A-Za-z_]+:/ { flag=0 }
    flag && /^  - /   {
      gsub(/^  - "?/, "")
      gsub(/"$/, "")
      print
    }
  ')

  while IFS= read -r pattern; do
    [[ -z "$pattern" ]] && continue

    # Match tracked AND untracked-but-not-ignored files (so newly added files
    # don't show up as dead refs before their first commit).
    matched=$(
      {
        git ls-files -- "$pattern" 2>/dev/null
        git ls-files --others --exclude-standard -- "$pattern" 2>/dev/null
      } | sort -u
    )

    if [[ -z "$matched" ]]; then
      DEAD_REFS+=("$mem -> $pattern")
      HAS_DRIFT=1
      continue
    fi

    while IFS= read -r src; do
      [[ -z "$src" ]] && continue
      src_epoch=$(git log -1 --format=%ct -- "$src" 2>/dev/null || true)
      [[ -z "$src_epoch" ]] && continue
      if (( src_epoch > last_epoch )); then
        commit_date=$(git log -1 --format=%cs -- "$src")
        STALE+=("$mem (last_updated $last_updated)  <-  $src (committed $commit_date)")
        HAS_DRIFT=1
      fi
    done <<< "$matched"
  done <<< "$tracks"
done < <(find "$MEMORY_DIR" -name "*.md" -not -name "README.md" -not -path "*/meta/changelog.md" 2>/dev/null | sort)

echo "=== AI memory drift report ==="
echo

if (( ${#STALE[@]} > 0 )); then
  echo "STALE (source committed after memory's last_updated):"
  for e in "${STALE[@]}"; do echo "  - $e"; done
  echo
fi

if (( ${#DEAD_REFS[@]} > 0 )); then
  echo "DEAD REFS (tracks: pattern matches nothing — renamed or deleted source):"
  for e in "${DEAD_REFS[@]}"; do echo "  - $e"; done
  echo
fi

if (( HAS_DRIFT == 0 )); then
  echo "Memory is fresh."
fi

exit $HAS_DRIFT
