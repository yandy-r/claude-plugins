#!/usr/bin/env bash
# Validate parallel-plan.md structure
# Usage: validate-plan.sh <plan-file>

set -euo pipefail

# Source the shared resolver to get PLANS_ROOT for path resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]:-$0}")" && pwd)"
SHARED_DIR="${SCRIPT_DIR}/../../../shared/scripts"

if [[ -f "${SHARED_DIR}/resolve-plans-dir.sh" ]]; then
  # shellcheck source=../../../shared/scripts/resolve-plans-dir.sh
  source "${SHARED_DIR}/resolve-plans-dir.sh"
fi

PLAN_FILE="${1:-}"

if [[ -z "$PLAN_FILE" ]]; then
  echo "ERROR: Plan file path required"
  echo "Usage: validate-plan.sh <plan-file>"
  exit 1
fi

# Always resolve relative paths against PLANS_ROOT
if [[ "$PLAN_FILE" != /* && -n "${PLANS_ROOT:-}" ]]; then
  PLAN_FILE="${PLANS_ROOT}/${PLAN_FILE}"
fi

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "ERROR: Plan file not found: $PLAN_FILE"
  exit 1
fi

echo "Validating plan structure: $PLAN_FILE"
echo ""

# Check required sections
ERRORS=0
WARNINGS=0

# Title check
if ! grep -q "^# " "$PLAN_FILE"; then
  echo "✗ ERROR: Missing title (# heading)"
  ERRORS=$((ERRORS + 1))
else
  echo "✓ Title present"
fi

# Critically Relevant Files section
if ! grep -q "## Critically Relevant Files" "$PLAN_FILE"; then
  echo "✗ ERROR: Missing 'Critically Relevant Files' section"
  ERRORS=$((ERRORS + 1))
else
  echo "✓ Critically Relevant Files section present"
fi

# Implementation Plan section
if ! grep -q "## Implementation Plan" "$PLAN_FILE"; then
  echo "✗ ERROR: Missing 'Implementation Plan' section"
  ERRORS=$((ERRORS + 1))
else
  echo "✓ Implementation Plan section present"
fi

# Advice section
if ! grep -q "## Advice" "$PLAN_FILE"; then
  echo "⚠ WARNING: Missing 'Advice' section"
  WARNINGS=$((WARNINGS + 1))
else
  echo "✓ Advice section present"
fi

# Task dependencies
if ! grep -q "Depends on" "$PLAN_FILE"; then
  echo "⚠ WARNING: No task dependencies found"
  echo "  Tasks should include 'Depends on [none]' or 'Depends on [1.1, 2.3]'"
  WARNINGS=$((WARNINGS + 1))
else
  TASK_COUNT=$(grep -c "Depends on" "$PLAN_FILE")
  echo "✓ Task dependencies found ($TASK_COUNT tasks)"
fi

# Phase structure
if ! grep -q "### Phase" "$PLAN_FILE"; then
  echo "⚠ WARNING: No phase structure found (### Phase N)"
  WARNINGS=$((WARNINGS + 1))
else
  PHASE_COUNT=$(grep -c "### Phase" "$PLAN_FILE")
  echo "✓ Phase structure present ($PHASE_COUNT phases)"
fi

# Task structure
if ! grep -q "#### Task" "$PLAN_FILE"; then
  echo "✗ ERROR: No tasks found (#### Task N.N)"
  ERRORS=$((ERRORS + 1))
else
  TASK_COUNT=$(grep -c "#### Task" "$PLAN_FILE")
  echo "✓ Tasks defined ($TASK_COUNT tasks)"
fi

# Optional: --no-worktree plans omit this. Single-worktree contract: **Parent** only.
if grep -q "^## Worktree Setup" "$PLAN_FILE"; then
  WORKTREE_TASK_COUNT=$(grep -c "^\- \*\*Worktree\*\*:" "$PLAN_FILE" 2>/dev/null || true)
  echo "✓ Worktree section present (## Worktree Setup; ${WORKTREE_TASK_COUNT} optional per-task **Worktree** line(s), if any)"
fi

echo ""
echo "========================================="

if [[ $ERRORS -eq 0 && $WARNINGS -eq 0 ]]; then
  echo "✓ Plan structure is valid"
  exit 0
elif [[ $ERRORS -eq 0 ]]; then
  echo "✓ Plan structure is valid with $WARNINGS warning(s)"
  exit 0
else
  echo "✗ Plan structure has $ERRORS error(s) and $WARNINGS warning(s)"
  exit 1
fi
