#!/usr/bin/env bash
# Ensure .opencode-plugin/agents matches generator output, parses as YAML
# frontmatter + body, and has no Claude-only residue.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
AGENTS_DIR="${REPO_ROOT}/.opencode-plugin/agents"

echo "== Sync check (generator --check) =="
python3 "${REPO_ROOT}/scripts/generate_opencode_agents.py" --check

echo "== Frontmatter lint =="
python3 - <<'PY' "${AGENTS_DIR}"
import re
import sys
from pathlib import Path

import yaml

root = Path(sys.argv[1])
# opencode agent frontmatter keys (per opencode.ai/docs/agents). `name` and
# `title` are intentionally absent — opencode uses the filename as the agent
# identifier.
ALLOWED = {
    "description",
    "mode",
    "model",
    "prompt",
    "tools",
    "permission",
    "temperature",
    "top_p",
    "steps",
    "disable",
    "hidden",
    "color",
}
errors = 0
for path in sorted(root.glob("*.md")):
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        print(f"MISSING frontmatter: {path}", file=sys.stderr)
        errors += 1
        continue
    data = yaml.safe_load(match.group(1)) or {}
    unknown = set(data) - ALLOWED
    if unknown:
        print(f"UNEXPECTED frontmatter keys in {path}: {sorted(unknown)}", file=sys.stderr)
        errors += 1
    description = str(data.get("description") or "").strip()
    if not description:
        print(f"MISSING required 'description' in {path}", file=sys.stderr)
        errors += 1
    mode = data.get("mode")
    if mode is not None and mode not in {"primary", "subagent", "all"}:
        print(f"INVALID mode {mode!r} in {path} (expected primary|subagent|all)", file=sys.stderr)
        errors += 1
    tools = data.get("tools")
    if tools is not None and not isinstance(tools, dict):
        print(f"TOOLS must be an object (got {type(tools).__name__}) in {path}", file=sys.stderr)
        errors += 1
if errors:
    sys.exit(1)
PY

echo "== Content policy (generated agents) =="
BAD=0
while IFS= read -r -d '' f; do
  if grep -qE '/ycc:|\bycc:|CLAUDE_PLUGIN_ROOT|~/\.claude/|\.claude-plugin/|TeamCreate|TeamDelete|TaskCreate|TaskUpdate|TaskList|TaskGet|SendMessage|AskUserQuestion|TodoWrite|subagent_type:' "$f" 2>/dev/null; then
    echo "FORBIDDEN pattern in $f:" >&2
    grep -nE '/ycc:|\bycc:|CLAUDE_PLUGIN_ROOT|~/\.claude/|\.claude-plugin/|TeamCreate|TeamDelete|TaskCreate|TaskUpdate|TaskList|TaskGet|SendMessage|AskUserQuestion|TodoWrite|subagent_type:' "$f" >&2 || true
    BAD=1
  fi
done < <(find "$AGENTS_DIR" -maxdepth 1 -name '*.md' -print0)

if [[ "$BAD" -ne 0 ]]; then
  echo "validate-opencode-agents.sh: content policy failed." >&2
  exit 1
fi

echo "OK: .opencode-plugin/agents is in sync and passes opencode-native lint."
