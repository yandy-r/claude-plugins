#!/usr/bin/env bash
# Ensure .cursor-plugin/agents matches generator output and has no banned Claude-only residue.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
AGENTS_DIR="${REPO_ROOT}/.cursor-plugin/agents"

echo "== Sync check (generator --check) =="
python3 "${REPO_ROOT}/scripts/generate_cursor_agents.py" --check

echo "== Content policy (generated agents) =="
# Fail if obvious Claude-plugin residue remains in Cursor output
BAD=0
while IFS= read -r -d '' f; do
  if grep -qE '/ycc:|~/.claude/|\bycc:' "$f" 2>/dev/null; then
    echo "FORBIDDEN pattern in $f:" >&2
    grep -nE '/ycc:|~/.claude/|\bycc:' "$f" >&2 || true
    BAD=1
  fi
  if grep -q 'mcp\*\*' "$f" 2>/dev/null; then
    echo "Malformed mcp** token in $f:" >&2
    grep -n 'mcp\*\*' "$f" >&2 || true
    BAD=1
  fi
done < <(find "$AGENTS_DIR" -maxdepth 1 -name '*.md' -print0)

if [[ "$BAD" -ne 0 ]]; then
  echo "validate-cursor-agents.sh: content policy failed." >&2
  exit 1
fi

echo "OK: .cursor-plugin/agents is in sync and passes content policy."
