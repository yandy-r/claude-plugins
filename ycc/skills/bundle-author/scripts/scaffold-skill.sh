#!/usr/bin/env bash
# scaffold-skill.sh — Scaffold a new skill in ycc/skills/<skill-name>/,
# optionally with a matching command and/or agent.
#
# Usage: scaffold-skill.sh <skill-name> [--with-command] [--with-agent]
#
# Exit codes:
#   0 - Scaffolding completed successfully
#   1 - Invalid arguments, name validation failure, or collision detected

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

SKILL_NAME=""
WITH_COMMAND=0
WITH_AGENT=0

usage() {
    cat <<EOF
Usage: scaffold-skill.sh <skill-name> [--with-command] [--with-agent]

Scaffold a new skill in ycc/skills/<skill-name>/, optionally with a
matching command under ycc/commands/ and/or an agent under ycc/agents/.
Templates are read from ycc/skills/bundle-author/references/templates/.

Options:
  --with-command   Also create ycc/commands/<skill-name>.md
  --with-agent     Also create ycc/agents/<skill-name>.md
  -h, --help       Show this help
EOF
}

while [[ $# -gt 0 ]]; do
    case "$1" in
        --with-command)
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

# Helper: render a template with NAME and DESCRIPTION substitutions
render() {
    local src="$1"
    local dst="$2"
    local name="$3"
    local desc="$4"
    sed -e "s|{{NAME}}|${name}|g" -e "s|{{DESCRIPTION}}|${desc}|g" "$src" > "$dst"
}

# Create skill directory and render SKILL.md
mkdir -p "${REPO_ROOT}/ycc/skills/${SKILL_NAME}"
render \
    "${TEMPLATES_DIR}/skill-template.md" \
    "${REPO_ROOT}/ycc/skills/${SKILL_NAME}/SKILL.md" \
    "${SKILL_NAME}" \
    "${DESC}"
echo "${REPO_ROOT}/ycc/skills/${SKILL_NAME}/SKILL.md"

# Optionally render command stub
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
