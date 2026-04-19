#!/usr/bin/env bash
# Enforce the skill↔command pairing policy:
#   - Every skill under ycc/skills/<name>/SKILL.md must have a matching
#     ycc/commands/<name>.md, UNLESS the skill's frontmatter declares
#     `command: false` (explicit skill-only opt-out).
#   - Every command under ycc/commands/<name>.md must have a matching skill.
#   - Skills with `command: false` must NOT have a matching command (pick one).
#
# See CONTRIBUTING.md "Skills and commands: when to pair" for the rationale.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SKILLS_DIR="${REPO_ROOT}/ycc/skills"
COMMANDS_DIR="${REPO_ROOT}/ycc/commands"

[[ -d "${SKILLS_DIR}" ]] || { echo "validate-ycc-commands.sh: missing ${SKILLS_DIR}" >&2; exit 1; }
[[ -d "${COMMANDS_DIR}" ]] || { echo "validate-ycc-commands.sh: missing ${COMMANDS_DIR}" >&2; exit 1; }

python3 - "${SKILLS_DIR}" "${COMMANDS_DIR}" <<'PY'
import re
import sys
from pathlib import Path

try:
    import yaml
    def load_frontmatter(text: str) -> dict:
        m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
        return (yaml.safe_load(m.group(1)) or {}) if m else {}
except ImportError:
    def load_frontmatter(text: str) -> dict:
        m = re.match(r"^---\n(.*?)\n---\n", text, re.DOTALL)
        if not m:
            return {}
        out: dict = {}
        for line in m.group(1).splitlines():
            km = re.match(r"^([a-zA-Z_][a-zA-Z0-9_-]*):\s*(.*)$", line)
            if not km:
                continue
            key, val = km.group(1), km.group(2).strip()
            if val.startswith(('"', "'")):
                val = val.strip("\"'")
            if val.lower() in {"true", "false"}:
                out[key] = (val.lower() == "true")
            else:
                out[key] = val
        return out

skills_dir = Path(sys.argv[1])
commands_dir = Path(sys.argv[2])

# Collect skills: directories with SKILL.md, excluding _shared.
skills: dict[str, dict] = {}
for skill_md in sorted(skills_dir.glob("*/SKILL.md")):
    name = skill_md.parent.name
    if name.startswith("_"):
        continue
    frontmatter = load_frontmatter(skill_md.read_text(encoding="utf-8"))
    skills[name] = frontmatter

# Collect commands: top-level .md files.
commands: set[str] = {
    p.stem for p in sorted(commands_dir.glob("*.md"))
}

errors: list[str] = []

# Rule 1 & 3: every skill either has a command, or declares command: false.
for name, frontmatter in skills.items():
    opt_out = frontmatter.get("command") is False
    has_command = name in commands
    if opt_out and has_command:
        errors.append(
            f"skill '{name}' declares 'command: false' but "
            f"ycc/commands/{name}.md exists — pick one (delete the command "
            f"or remove the opt-out)"
        )
    elif not opt_out and not has_command:
        errors.append(
            f"skill '{name}' has no matching ycc/commands/{name}.md "
            f"(add the command, or declare 'command: false' in the skill "
            f"frontmatter for explicit skill-only)"
        )

# Rule 2: every command has a matching skill.
for name in sorted(commands):
    if name not in skills:
        errors.append(
            f"command '{name}' has no matching ycc/skills/{name}/SKILL.md "
            f"(orphan command — add the skill or remove the command)"
        )

if errors:
    print("validate-ycc-commands.sh: skill↔command pairing failed:", file=sys.stderr)
    for err in errors:
        print(f"  - {err}", file=sys.stderr)
    sys.exit(1)

skill_only = sum(1 for f in skills.values() if f.get("command") is False)
paired = len(skills) - skill_only
print(
    f"OK: {paired} skill↔command pairs, {skill_only} skill-only "
    f"(command: false), {len(commands)} commands."
)
PY
