#!/usr/bin/env bash
# Atomically bump version across the two hand-edited source-of-truth JSON files.
#
# Usage:
#   bump-version.sh <new-version>
#
# Updates:
#   - ycc/.codex-plugin/plugin.json (.version)
#   - .codex-plugin/marketplace.json (.metadata.version and .plugins[0].version)
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/../../../.." && pwd)"

usage() {
    cat <<EOF
Usage: bump-version.sh <new-version>

Atomically bump version across the two hand-edited source-of-truth files:
  - ycc/.codex-plugin/plugin.json (.version)
  - .codex-plugin/marketplace.json (.metadata.version and .plugins[0].version)

Does not touch generated bundles. Validates semver format (x.y.z).
EOF
}

if [[ $# -eq 0 ]]; then
    usage >&2
    exit 1
fi

case "$1" in
    -h|--help)
        usage
        exit 0
        ;;
esac

NEW_VERSION="$1"

if ! [[ "${NEW_VERSION}" =~ ^[0-9]+\.[0-9]+\.[0-9]+$ ]]; then
    echo "bump-version.sh: invalid semver '${NEW_VERSION}' (expected x.y.z)" >&2
    exit 1
fi

python3 - "${REPO_ROOT}" "${NEW_VERSION}" <<'PY'
import json, sys, pathlib

repo_root = pathlib.Path(sys.argv[1])
new_version = sys.argv[2]

plugin_path = repo_root / "ycc" / ".claude-plugin" / "plugin.json"
marketplace_path = repo_root / ".claude-plugin" / "marketplace.json"

def load(p):
    return json.loads(p.read_text())

def dump(p, data):
    p.write_text(json.dumps(data, indent=2, ensure_ascii=False) + "\n")

plugin = load(plugin_path)
marketplace = load(marketplace_path)

old_plugin = plugin.get("version")
old_meta = marketplace["metadata"]["version"]
old_entry = marketplace["plugins"][0]["version"]

plugin["version"] = new_version
marketplace["metadata"]["version"] = new_version
marketplace["plugins"][0]["version"] = new_version

dump(plugin_path, plugin)
dump(marketplace_path, marketplace)

print(f"ycc/.codex-plugin/plugin.json:       {old_plugin} -> {new_version}")
print(f".codex-plugin/marketplace.json meta: {old_meta} -> {new_version}")
print(f".codex-plugin/marketplace.json entry: {old_entry} -> {new_version}")
PY

echo "bump-version.sh: OK (${NEW_VERSION})"
