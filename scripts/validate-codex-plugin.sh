#!/usr/bin/env bash
# Ensure Codex plugin metadata matches generator output and parses as JSON.
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"

echo "== Sync check (generator --check) =="
python3 "${REPO_ROOT}/scripts/generate_codex_plugin.py" --check

echo "== JSON lint =="
python3 -m json.tool "${REPO_ROOT}/.codex-plugin/ycc/.codex-plugin/plugin.json" >/dev/null
python3 -m json.tool "${REPO_ROOT}/.codex-plugin/ycc/.mcp.json" >/dev/null
python3 -m json.tool "${REPO_ROOT}/.agents/plugins/marketplace.json" >/dev/null

echo "OK: Codex plugin metadata is in sync and valid JSON."
