#!/usr/bin/env bash
# Ensure opencode plugin metadata (opencode.json + AGENTS.md) matches generator
# output and parses as JSON / valid Markdown.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
BUNDLE_ROOT="${REPO_ROOT}/.opencode-plugin"

echo "== Sync check (generator --check) =="
python3 "${REPO_ROOT}/scripts/generate_opencode_plugin.py" --check

echo "== JSON lint =="
python3 -m json.tool "${BUNDLE_ROOT}/opencode.json" >/dev/null

echo "== Schema assertions =="
python3 - <<'PY' "${BUNDLE_ROOT}/opencode.json"
import json
import sys
from pathlib import Path

path = Path(sys.argv[1])
data = json.loads(path.read_text(encoding="utf-8"))

errors = []
if data.get("$schema") != "https://opencode.ai/config.json":
    errors.append(f"$schema={data.get('$schema')!r} (expected 'https://opencode.ai/config.json')")
if "instructions" not in data or not isinstance(data["instructions"], list):
    errors.append("instructions must be a list")
elif "AGENTS.md" not in data["instructions"]:
    errors.append("instructions must include 'AGENTS.md'")

mcp = data.get("mcp")
if mcp is not None:
    if not isinstance(mcp, dict):
        errors.append("mcp must be an object")
    else:
        for name, entry in mcp.items():
            if not isinstance(entry, dict):
                errors.append(f"mcp.{name} must be an object")
                continue
            t = entry.get("type")
            if t not in {"local", "remote"}:
                errors.append(f"mcp.{name}.type must be 'local' or 'remote' (got {t!r})")
            if t == "local":
                cmd = entry.get("command")
                if not isinstance(cmd, list) or not cmd:
                    errors.append(f"mcp.{name}.command must be a non-empty list")
            if t == "remote":
                if not isinstance(entry.get("url"), str):
                    errors.append(f"mcp.{name}.url must be a string")

if errors:
    for err in errors:
        print(f"  {err}", file=sys.stderr)
    sys.exit(1)
PY

echo "== AGENTS.md existence =="
if [[ ! -f "${BUNDLE_ROOT}/AGENTS.md" ]]; then
  echo "MISSING ${BUNDLE_ROOT}/AGENTS.md" >&2
  exit 1
fi

echo "OK: opencode plugin metadata is in sync and valid."
