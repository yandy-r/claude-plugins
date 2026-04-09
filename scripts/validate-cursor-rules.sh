#!/usr/bin/env bash
# Ensure .cursor-plugin/rules matches generator output and passes policy + frontmatter lint.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
RULES_DIR="${REPO_ROOT}/.cursor-plugin/rules"

echo "== Sync check (generator --check) =="
python3 "${REPO_ROOT}/scripts/generate_cursor_rules.py" --check

echo "== Frontmatter lint =="
python3 "${REPO_ROOT}/scripts/generate_cursor_rules.py" --lint

echo "== Content policy (generated rules) =="
BAD=0
while IFS= read -r -d '' f; do
  [[ "$f" == *.mdc ]] || continue
  if grep -qE '/ycc:|~/.claude/|\bycc:|CLAUDE_PLUGIN_ROOT|\$\{HOME\}/\.claude/|\$HOME/\.claude/' "$f" 2>/dev/null; then
    echo "FORBIDDEN pattern in $f:" >&2
    grep -nE '/ycc:|~/.claude/|\bycc:|CLAUDE_PLUGIN_ROOT|\$\{HOME\}/\.claude/|\$HOME/\.claude/' "$f" >&2 || true
    BAD=1
  fi
  if grep -q 'mcp\*\*' "$f" 2>/dev/null; then
    echo "Malformed mcp** token in $f:" >&2
    grep -n 'mcp\*\*' "$f" >&2 || true
    BAD=1
  fi
done < <(find "$RULES_DIR" -type f -print0)

if [[ "$BAD" -ne 0 ]]; then
  echo "validate-cursor-rules.sh: content policy failed." >&2
  exit 1
fi

echo "OK: .cursor-plugin/rules is in sync and passes lint + content policy."
