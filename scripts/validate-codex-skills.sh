#!/usr/bin/env bash
# Ensure plugins/ycc/skills matches generator output and strips Claude-only residue.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/.codex-plugin/ycc/skills"

echo "== Sync check (generator --check) =="
python3 "${REPO_ROOT}/scripts/generate_codex_skills.py" --check

echo "== Frontmatter lint =="
python3 - <<'PY' "${SKILLS_DIR}"
import re
import sys
from pathlib import Path

import yaml

root = Path(sys.argv[1])
errors = 0
for path in sorted(root.rglob("SKILL.md")):
    text = path.read_text(encoding="utf-8")
    match = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
    if not match:
        print(f"MISSING frontmatter: {path}", file=sys.stderr)
        errors += 1
        continue
    data = yaml.safe_load(match.group(1)) or {}
    if set(data) - {"name", "description", "license", "allowed-tools", "metadata"}:
        print(f"UNEXPECTED frontmatter keys in {path}: {sorted(set(data) - {'name', 'description', 'license', 'allowed-tools', 'metadata'})}", file=sys.stderr)
        errors += 1
    if "name" not in data or "description" not in data:
        print(f"MISSING required skill keys in {path}", file=sys.stderr)
        errors += 1
    elif len(data["description"]) > 1024:
        print(f"DESCRIPTION too long in {path}: {len(data['description'])} chars", file=sys.stderr)
        errors += 1
if errors:
    sys.exit(1)
PY

echo "== Content policy (generated skills) =="
# Allow-list: these files are copied verbatim by the Codex generator because
# they describe all three deployment targets. The same Claude-specific
# references the content policy normally forbids are intentional here.
# Must mirror VERBATIM_SKILL_FILES in scripts/generate_codex_common.py.
# Note: _shared/references/target-capability-matrix.md is remapped to
# .codex-plugin/ycc/shared/ (outside SKILLS_DIR) so it never reaches this loop.
VERBATIM=(
  "${SKILLS_DIR}/hooks-workflow/references/support-notes.md"
  "${SKILLS_DIR}/hooks-workflow/scripts/build-hook-config.sh"
  "${SKILLS_DIR}/compatibility-audit/scripts/audit-install-assumptions.sh"
  "${SKILLS_DIR}/compatibility-audit/scripts/audit-target-features.sh"
  "${SKILLS_DIR}/compatibility-audit/references/reading-the-report.md"
)
is_verbatim() {
  local f="$1" v
  for v in "${VERBATIM[@]}"; do
    [[ "$f" == "$v" ]] && return 0
  done
  return 1
}

BAD=0
while IFS= read -r -d '' f; do
  if is_verbatim "$f"; then
    continue
  fi
  if grep -qE '/ycc:|\bycc:|CLAUDE_PLUGIN_ROOT|~/.claude/|\.claude-plugin/|TeamCreate|TeamDelete|TaskCreate|TaskUpdate|TaskList|TaskGet|SendMessage|AskUserQuestion|TodoWrite|subagent_type:' "$f" 2>/dev/null; then
    echo "FORBIDDEN pattern in $f:" >&2
    grep -nE '/ycc:|\bycc:|CLAUDE_PLUGIN_ROOT|~/.claude/|\.claude-plugin/|TeamCreate|TeamDelete|TaskCreate|TaskUpdate|TaskList|TaskGet|SendMessage|AskUserQuestion|TodoWrite|subagent_type:' "$f" >&2 || true
    BAD=1
  fi
done < <(find "$SKILLS_DIR" -type f -print0)

if [[ "$BAD" -ne 0 ]]; then
  echo "validate-codex-skills.sh: content policy failed." >&2
  exit 1
fi

echo "OK: .codex-plugin/ycc/skills is in sync and passes Codex-native lint."
