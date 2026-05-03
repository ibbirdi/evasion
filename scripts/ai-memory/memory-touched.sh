#!/usr/bin/env bash
# scripts/ai-memory/memory-touched.sh
#
# Quick coarse-grained check used by hooks. Exits:
#   0 if the change set has no relevant source changes, OR
#     if the change set has source changes AND a docs/ai/ or AGENTS.md change.
#   1 if source changed but no memory was touched (warning: memory likely stale).
#
# Usage:
#   bash scripts/ai-memory/memory-touched.sh staged    # for pre-commit hook
#   bash scripts/ai-memory/memory-touched.sh working   # for Claude Code Stop hook

set -euo pipefail

cd "$(git rev-parse --show-toplevel)"

MODE="${1:-working}"

case "$MODE" in
  staged)
    files=$(git diff --cached --name-only)
    ;;
  working)
    # All modified, added, and deleted (tracked OR untracked).
    files=$(git status --porcelain | sed 's/^...//')
    ;;
  *)
    echo "usage: $0 staged|working" >&2
    exit 2
    ;;
esac

[[ -z "$files" ]] && exit 0

is_source() {
  case "$1" in
    docs/ai/*|scripts/ai-memory/*|.githooks/*|.claude/*) return 1 ;;
    AGENTS.md|README.md|.gitignore|Gemfile|Gemfile.lock) return 1 ;;
    ios-native/*|scripts/*|fastlane/*) return 0 ;;
    *.swift|*.plist|*.xcstrings|*.m4a) return 0 ;;
    *) return 1 ;;
  esac
}

is_memory() {
  case "$1" in
    docs/ai/*|AGENTS.md) return 0 ;;
    *) return 1 ;;
  esac
}

src_count=0
mem_count=0
declare -a src_files

while IFS= read -r f; do
  [[ -z "$f" ]] && continue
  if is_source "$f"; then
    src_count=$((src_count + 1))
    src_files+=("$f")
  fi
  if is_memory "$f"; then
    mem_count=$((mem_count + 1))
  fi
done <<< "$files"

if (( src_count > 0 && mem_count == 0 )); then
  echo "AI memory may be stale." >&2
  echo "Source files changed in this $MODE set, but no docs/ai/ or AGENTS.md update:" >&2
  for f in "${src_files[@]:0:10}"; do
    echo "  - $f" >&2
  done
  if (( src_count > 10 )); then
    echo "  ... and $((src_count - 10)) more" >&2
  fi
  echo >&2
  echo "Update the matching memory file(s) and bump last_updated." >&2
  echo "For a precise report: bash scripts/ai-memory/check-drift.sh" >&2
  exit 1
fi

exit 0
