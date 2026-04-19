#!/usr/bin/env bash
# scaffold-skill.sh — Scaffold a new skill in ycc/skills/<skill-name>/.
#
# Default: also creates the matching command at ycc/commands/<skill-name>.md
# because every skill pairs with a slash command unless explicitly opted out.
# Pass --skill-only to suppress the command AND stamp `command: false` into
# the skill's frontmatter (required so validate-ycc-commands.sh stays green).
#
# Usage: scaffold-skill.sh <skill-name> [--skill-only] [--with-agent]
#
# Exit codes:
#   0 - Scaffolding completed successfully
#   1 - Invalid arguments, name validation failure, or collision detected

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

SKILL_NAME=""
WITH_COMMAND=1
WITH_AGENT=0

usage() {
    cat <<EOF
Usage: scaffold-skill.sh <skill-name> [--skill-only] [--with-agent]

Scaffold a new skill in ycc/skills/<skill-name>/. By default also creates
the matching command under ycc/commands/<skill-name>.md. Optionally
creates an agent under ycc/agents/<skill-name>.md.
Templates are read from ycc/skills/bundle-author/references/templates/.

Options:
  --skill-only     Do NOT create ycc/commands/<skill-name>.md and stamp
                   'command: false' into the skill frontmatter. Use only
                   when the skill is never directly slash-invokable
                   (e.g., passive behavioral guidelines).
  --with-agent     Also create ycc/agents/<skill-name>.md
  -h, --help       Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --skill-only)
            WITH_COMMAND=0
            shift
            ;;
        --with-command)
            # Accepted for backward compatibility; command is now the default.
            WITH_COMMAND=1
            shift
            ;;
        --with-agent)
            WITH_AGENT=1
            shift
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        -*)
            echo "scaffold-skill.sh: unknown flag: $1" >&2
            usage >&2
            exit 1
            ;;
        *)
            if [[ -n "${SKILL_NAME}" ]]; then
                echo "scaffold-skill.sh: unexpected argument: $1" >&2
                usage >&2
                exit 1
            fi
            SKILL_NAME="$1"
            shift
            ;;
    esac
done

# Validate skill name is provided
if [[ -z "${SKILL_NAME}" ]]; then
    echo "scaffold-skill.sh: missing required argument: <skill-name>" >&2
    usage >&2
    exit 1
fi

# Validate skill name format
if ! [[ "${SKILL_NAME}" =~ ^[a-z][a-z0-9]*(-[a-z0-9]+)*$ ]]; then
    echo "scaffold-skill.sh: invalid skill name '${SKILL_NAME}'" >&2
    echo "  Must match: ^[a-z][a-z0-9]*(-[a-z0-9]+)*\$" >&2
    exit 1
fi

# Collision checks
[[ -e "${REPO_ROOT}/ycc/skills/${SKILL_NAME}" ]] && {
    echo "scaffold-skill.sh: refuse: ycc/skills/${SKILL_NAME} already exists" >&2
    exit 1
}

if [[ "${WITH_COMMAND}" -eq 1 ]]; then
    [[ -e "${REPO_ROOT}/ycc/commands/${SKILL_NAME}.md" ]] && {
        echo "scaffold-skill.sh: refuse: ycc/commands/${SKILL_NAME}.md already exists" >&2
        exit 1
    }
fi

if [[ "${WITH_AGENT}" -eq 1 ]]; then
    [[ -e "${REPO_ROOT}/ycc/agents/${SKILL_NAME}.md" ]] && {
        echo "scaffold-skill.sh: refuse: ycc/agents/${SKILL_NAME}.md already exists" >&2
        exit 1
    }
fi

# Verify templates directory exists
TEMPLATES_DIR="${REPO_ROOT}/ycc/skills/bundle-author/references/templates"
[[ -d "${TEMPLATES_DIR}" ]] || {
    echo "scaffold-skill.sh: missing templates dir: ${TEMPLATES_DIR}" >&2
    exit 1
}

# Default description placeholder
DESC="TODO: one-line description for ${SKILL_NAME}"

# Skill-only mode stamps `command: false` into the frontmatter so
# validate-ycc-commands.sh recognizes the missing command as intentional.
if [[ "${WITH_COMMAND}" -eq 0 ]]; then
    COMMAND_OPT_OUT="command: false"$'\n'
else
    COMMAND_OPT_OUT=""
fi

# Helper: render a template with NAME, DESCRIPTION, and COMMAND_OPT_OUT substitutions.
# COMMAND_OPT_OUT is a multi-line-capable value, so use a Python helper rather than sed.
render() {
    local src="$1"
    local dst="$2"
    local name="$3"
    local desc="$4"
    local opt_out="${5:-}"
    NAME="$name" DESCRIPTION="$desc" COMMAND_OPT_OUT="$opt_out" \
        python3 -c '
import os, sys
text = open(sys.argv[1], encoding="utf-8").read()
for key in ("NAME", "DESCRIPTION", "COMMAND_OPT_OUT"):
    text = text.replace("{{" + key + "}}", os.environ.get(key, ""))
open(sys.argv[2], "w", encoding="utf-8").write(text)
' "$src" "$dst"
}

# Create skill directory and render SKILL.md
mkdir -p "${REPO_ROOT}/ycc/skills/${SKILL_NAME}"
render \
    "${TEMPLATES_DIR}/skill-template.md" \
    "${REPO_ROOT}/ycc/skills/${SKILL_NAME}/SKILL.md" \
    "${SKILL_NAME}" \
    "${DESC}" \
    "${COMMAND_OPT_OUT}"
echo "${REPO_ROOT}/ycc/skills/${SKILL_NAME}/SKILL.md"

# Optionally render command stub (default; suppressed by --skill-only)
if [[ "${WITH_COMMAND}" -eq 1 ]]; then
    render \
        "${TEMPLATES_DIR}/command-template.md" \
        "${REPO_ROOT}/ycc/commands/${SKILL_NAME}.md" \
        "${SKILL_NAME}" \
        "${DESC}"
    echo "${REPO_ROOT}/ycc/commands/${SKILL_NAME}.md"
fi

# Optionally render agent stub
if [[ "${WITH_AGENT}" -eq 1 ]]; then
    render \
        "${TEMPLATES_DIR}/agent-template.md" \
        "${REPO_ROOT}/ycc/agents/${SKILL_NAME}.md" \
        "${SKILL_NAME}" \
        "${DESC}"
    echo "${REPO_ROOT}/ycc/agents/${SKILL_NAME}.md"
fi

exit 0
