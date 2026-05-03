#!/usr/bin/env bash
# scripts/ai-memory/stop-hook.sh
#
# Wrapper for the Claude Code `Stop` hook. Reads JSON input on stdin (per Claude
# Code hooks contract), checks for memory drift, and emits a JSON response that
# either lets Claude stop or re-prompts it with a memory-update reminder.
#
# Wired in .claude/settings.json:
#   "Stop": [{"hooks": [{"type": "command", "command": "\"$CLAUDE_PROJECT_DIR\"/scripts/ai-memory/stop-hook.sh"}]}]

set -euo pipefail

# Read hook input (JSON on stdin). Use jq if available; fall back to grep.
INPUT=$(cat)

stop_active=$(printf '%s' "$INPUT" | grep -o '"stop_hook_active"[[:space:]]*:[[:space:]]*true' || true)

# If the previous stop already triggered our hook, let Claude end the session
# (otherwise we'd loop the agent forever).
if [[ -n "$stop_active" ]]; then
  exit 0
fi

cd "$(git rev-parse --show-toplevel 2>/dev/null || echo .)"

# Reuse the shared drift detector. Capture its stderr — that is the human-readable warning.
warning=$(bash scripts/ai-memory/memory-touched.sh working 2>&1 1>/dev/null) || true

# memory-touched.sh exits 1 when source changed without memory; in that case `warning` is non-empty.
if [[ -z "$warning" ]]; then
  exit 0
fi

# Escape the warning for JSON (handle quotes, backslashes, newlines).
escaped=$(printf '%s' "$warning" | python3 -c 'import json, sys; print(json.dumps(sys.stdin.read()))')

# Re-prompt the agent with the warning as additional context. Claude Code will
# inject this into the next turn so the agent can self-correct (update the
# memory file) before the session truly ends.
cat <<EOF
{
  "decision": "block",
  "reason": ${escaped}
}
EOF

exit 0
