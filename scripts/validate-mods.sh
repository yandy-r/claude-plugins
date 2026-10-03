#!/usr/bin/env bash
# Validate the Claude Code mods under ycc/mods against their marketplace.
#
# Checks, without needing the claude CLI:
#   - ycc/mods/.claude-plugin/marketplace.json is valid JSON named 'ycc-mods'
#   - every listed mod has a plugin.json whose name and version match its entry,
#     and a hooks/hooks.json that declares at least one hooks module
#   - every mod folder under ycc/mods is listed (no unlisted mods)
#
# When the claude CLI is on PATH, also runs 'claude plugin validate' per mod.
# 'claude plugin test' needs a signed-in CLI, so it stays a manual step.
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
MODS_ROOT="${REPO_ROOT}/ycc/mods"

command -v python3 >/dev/null 2>&1 || { echo "validate-mods.sh: python3 is required" >&2; exit 1; }
[[ -d "${MODS_ROOT}" ]] || { echo "validate-mods.sh: ${MODS_ROOT} not found" >&2; exit 1; }

python3 - "${MODS_ROOT}" <<'PY'
import json
import sys
from pathlib import Path

root = Path(sys.argv[1])
errors: list[str] = []


def load(path: Path) -> dict:
    try:
        data = json.loads(path.read_text(encoding="utf-8"))
    except (OSError, json.JSONDecodeError) as exc:
        errors.append(f"{path.relative_to(root.parent.parent)}: {exc}")
        return {}
    if not isinstance(data, dict):
        errors.append(f"{path}: expected a JSON object")
        return {}
    return data


market = load(root / ".claude-plugin" / "marketplace.json")
if market.get("name") != "ycc-mods":
    errors.append("marketplace.json: name must be 'ycc-mods'")

listed: set[str] = set()
for entry in market.get("plugins", []):
    name = entry.get("name", "")
    source = entry.get("source", "")
    listed.add(name)
    mod_dir = (root / source).resolve()
    if source != f"./{name}" or not mod_dir.is_dir():
        errors.append(f"{name}: source must be './{name}' and exist")
        continue
    manifest = load(mod_dir / ".claude-plugin" / "plugin.json")
    if manifest.get("name") != name:
        errors.append(f"{name}: plugin.json name is {manifest.get('name')!r}")
    if manifest.get("version") != entry.get("version"):
        errors.append(
            f"{name}: plugin.json version {manifest.get('version')!r} != marketplace {entry.get('version')!r}"
        )
    hooks = load(mod_dir / "hooks" / "hooks.json")
    modules = hooks.get("modules")
    if not isinstance(modules, list) or not modules:
        errors.append(f"{name}: hooks/hooks.json must list at least one module")
    for module in modules or []:
        if not (mod_dir / "hooks" / module).is_file():
            errors.append(f"{name}: hooks module {module} not found")

for manifest_path in sorted(root.glob("*/.claude-plugin/plugin.json")):
    name = manifest_path.parent.parent.name
    if name not in listed:
        errors.append(f"{name}: mod folder is not listed in marketplace.json")

if errors:
    for error in errors:
        print(f"validate-mods: {error}", file=sys.stderr)
    sys.exit(1)
print(f"OK: {len(listed)} mod(s) listed and well-formed.")
PY

if command -v claude >/dev/null 2>&1; then
    for mod_dir in "${MODS_ROOT}"/*/; do
        [[ -f "${mod_dir}.claude-plugin/plugin.json" ]] || continue
        echo "claude plugin validate ${mod_dir%/}"
        claude plugin validate "${mod_dir%/}" >/dev/null || {
            echo "validate-mods.sh: 'claude plugin validate' failed for ${mod_dir%/}" >&2
            exit 1
        }
    done
else
    echo "validate-mods.sh: claude CLI not on PATH — skipping 'claude plugin validate'"
fi
