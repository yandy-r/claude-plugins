#!/usr/bin/env bash
# Generate Cursor-native rules from ycc/rules (see scripts/generate_cursor_rules.py).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
exec python3 "${REPO_ROOT}/scripts/generate_cursor_rules.py" "$@"
