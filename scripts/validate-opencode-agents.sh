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
python3 - <<'PY' "${REPO_ROOT}" "${AGENTS_DIR}"
import re
import sys
from pathlib import Path

import yaml

repo_root = Path(sys.argv[1])
root = Path(sys.argv[2])
sys.path.insert(0, str(repo_root / "scripts"))

from opencode_v2_agent_schema import validate_agent_schema

THEME_COLORS = {
    "primary",
    "secondary",
    "accent",
    "success",
    "warning",
    "error",
    "info",
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
    if not isinstance(data, dict):
        print(f"FRONTMATTER must be an object in {path}", file=sys.stderr)
        errors += 1
        continue
    for message in validate_agent_schema(str(path), data):
        print(message, file=sys.stderr)
        errors += 1
    for index, rule in enumerate(data.get("permissions", [])):
        if isinstance(rule, dict) and rule.get("action") in {"bash", "task", "write"}:
            print(
                f"LEGACY permission action {rule['action']!r} in {path} permissions[{index}]",
                file=sys.stderr,
            )
            errors += 1
    description = str(data.get("description") or "").strip()
    if not description:
        print(f"MISSING required 'description' in {path}", file=sys.stderr)
        errors += 1
    if data.get("mode") != "subagent":
        print(f"MISSING 'mode: subagent' in {path}", file=sys.stderr)
        errors += 1
    # These files must stay provider-agnostic: a pinned model here would bake
    # one provider into every generated agent. Runtime model policy belongs in
    # opencode.json under `agents.<id>.model`, which merges by agent ID.
    if "model" in data:
        print(
            f"UNEXPECTED 'model' in {path}: {data['model']!r} "
            "(set per-agent models in opencode.json, not in generated agent files)",
            file=sys.stderr,
        )
        errors += 1
    color = data.get("color")
    if color is not None:
        if not isinstance(color, str):
            print(f"COLOR must be a string (got {type(color).__name__}) in {path}", file=sys.stderr)
            errors += 1
        elif color not in THEME_COLORS and not re.fullmatch(r"#[0-9a-fA-F]{6}", color):
            print(
                f"INVALID color {color!r} in {path} "
                "(expected #RRGGBB or opencode theme color)",
                file=sys.stderr,
            )
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
