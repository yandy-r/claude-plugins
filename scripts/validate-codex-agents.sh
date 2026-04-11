#!/usr/bin/env bash
# Ensure .codex/agents matches generator output and parses as TOML.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
AGENTS_DIR="${REPO_ROOT}/.codex-plugin/agents"

echo "== Sync check (generator --check) =="
python3 "${REPO_ROOT}/scripts/generate_codex_agents.py" --check

echo "== TOML lint =="
python3 - <<'PY' "${AGENTS_DIR}"
import sys
import tomllib
from pathlib import Path

root = Path(sys.argv[1])
for path in sorted(root.glob("*.toml")):
    with path.open("rb") as handle:
        payload = tomllib.load(handle)
    missing = [key for key in ("name", "description", "developer_instructions") if key not in payload]
    if missing:
        raise SystemExit(f"Missing required keys in {path}: {missing}")
PY

echo "== Content policy (generated agents) =="
BAD=0
while IFS= read -r -d '' f; do
  if grep -qE '/ycc:|\bycc:|CLAUDE_PLUGIN_ROOT|~/.claude/|\.claude-plugin/|TeamCreate|TeamDelete|TaskCreate|TaskUpdate|TaskList|TaskGet|SendMessage|AskUserQuestion|TodoWrite|subagent_type:' "$f" 2>/dev/null; then
    echo "FORBIDDEN pattern in $f:" >&2
    grep -nE '/ycc:|\bycc:|CLAUDE_PLUGIN_ROOT|~/.claude/|\.claude-plugin/|TeamCreate|TeamDelete|TaskCreate|TaskUpdate|TaskList|TaskGet|SendMessage|AskUserQuestion|TodoWrite|subagent_type:' "$f" >&2 || true
    BAD=1
  fi
done < <(find "$AGENTS_DIR" -maxdepth 1 -name '*.toml' -print0)

if [[ "$BAD" -ne 0 ]]; then
  echo "validate-codex-agents.sh: content policy failed." >&2
  exit 1
fi

echo "OK: .codex-plugin/agents is in sync and passes Codex-native lint."
