#!/usr/bin/env bash
# Generate docs/inventory.json and rewrite README generated regions (see scripts/generate_inventory.py).
set -euo pipefail
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
exec python3 "${REPO_ROOT}/scripts/generate_inventory.py" "$@"
