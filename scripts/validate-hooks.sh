#!/usr/bin/env bash
# Check that Claude hooks registered in ycc/settings/settings.json resolve on disk.
# Non-fatal: emits a WARNING but exits 0 so validate.sh continues.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

SETTINGS_FILE="${REPO_ROOT}/ycc/settings/settings.json"

# If settings file is absent or has no hooks section, nothing to check.
if [[ ! -f "${SETTINGS_FILE}" ]]; then
    exit 0
fi

# Extract the WorktreeCreate hook command (if any) using python3 for reliable JSON parsing.
hook_cmd=$(python3 - "${SETTINGS_FILE}" <<'PYEOF'
import json, sys
try:
    data = json.load(open(sys.argv[1]))
    hooks = data.get("hooks", {}).get("WorktreeCreate", [])
    for group in hooks:
        for h in group.get("hooks", []):
            if h.get("type") == "command":
                print(h["command"])
except Exception:
    pass
PYEOF
)

if [[ -z "${hook_cmd}" ]]; then
    # No WorktreeCreate command hook registered — nothing to verify.
    exit 0
fi

# Check whether the hook references the expected path.
EXPECTED_HOOK="${HOME}/.claude/hooks/worktree-create.sh"

if echo "${hook_cmd}" | grep -qF "worktree-create.sh"; then
    if [[ -f "${EXPECTED_HOOK}" ]]; then
        echo "OK: WorktreeCreate hook registered and ${EXPECTED_HOOK} resolves."
    else
        cat >&2 <<WARN
WARNING: WorktreeCreate hook is registered in ycc/settings/settings.json but
~/.claude/hooks/worktree-create.sh does not resolve. Until you run:
    ln -s "$(pwd)/ycc/settings/hooks" ~/.claude/hooks
the harness will fall back to its default worktree path (polluting
<repo>/.claude/worktrees/). See CONTRIBUTING.md → "Claude hooks symlink".
WARN
        # Non-fatal: exit 0 so validate.sh run continues.
    fi
fi
