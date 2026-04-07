#!/usr/bin/env bash
# Check that required planning documents exist
# Usage: check-prerequisites.sh <feature-name>
#
# Supports monorepo configurations via .plans-config file.
# See resolve-plans-dir.sh for configuration options.

set -euo pipefail

FEATURE_NAME="${1:-}"

# Source the shared resolver to get PLANS_DIR
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SHARED_DIR="${SCRIPT_DIR}/../../_shared/scripts"

if [[ -f "${SHARED_DIR}/resolve-plans-dir.sh" ]]; then
  # shellcheck source=../../_shared/scripts/resolve-plans-dir.sh
  source "${SHARED_DIR}/resolve-plans-dir.sh"
else
  # Fallback if shared resolver not found
  echo "WARNING: resolve-plans-dir.sh not found, using default path" >&2
  PLANS_DIR="docs/plans"
fi

PLAN_DIR="${PLANS_DIR}/${FEATURE_NAME}"

if [[ -z "$FEATURE_NAME" ]]; then
  echo "ERROR: Feature name required"
  echo "Usage: check-prerequisites.sh <feature-name>"
  exit 1
fi

if [[ ! -d "$PLAN_DIR" ]]; then
  echo "ERROR: Plan directory not found: $PLAN_DIR"
  echo "Create the directory first or run /shared-context to initialize planning"
  exit 1
fi

if [[ ! -f "${PLAN_DIR}/shared.md" ]]; then
  echo "ERROR: ${PLAN_DIR}/shared.md not found"
  echo ""
  echo "The parallel plan requires shared context to be created first."
  echo "Run the shared-context skill:"
  echo "  /shared-context ${FEATURE_NAME}"
  echo ""
  echo "This will create shared.md with relevant files, patterns, and documentation."
  exit 1
fi

echo "✓ Prerequisites satisfied"
echo "  Found: ${PLAN_DIR}/shared.md"

if [[ -f "${PLAN_DIR}/requirements.md" ]]; then
  echo "  Found: ${PLAN_DIR}/requirements.md"
fi

# Count other markdown files for context
OTHER_FILES=$(find "$PLAN_DIR" -maxdepth 1 -name "*.md" ! -name "shared.md" ! -name "requirements.md" ! -name "parallel-plan.md" | wc -l)
if [[ $OTHER_FILES -gt 0 ]]; then
  echo "  Found: $OTHER_FILES additional context file(s)"
fi

exit 0
