#!/usr/bin/env bash
# derive-rollback.sh — thin wrapper over the shared yci rollback helper.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)"
PLUGIN_ROOT="${CLAUDE_PLUGIN_ROOT:-$(cd "${SCRIPT_DIR}/../../.." && pwd -P)}"

exec bash "${PLUGIN_ROOT}/skills/_shared/scripts/derive-change-rollback.sh" "$@"
