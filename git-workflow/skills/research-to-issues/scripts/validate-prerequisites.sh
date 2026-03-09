#!/usr/bin/env bash
set -euo pipefail

# Validate prerequisites for research-to-issues skill
# Usage: validate-prerequisites.sh <research-dir>
#
# Checks:
#   1. gh CLI is installed and authenticated
#   2. Current directory is a git repo with a GitHub remote
#   3. Research directory exists and contains expected files
#
# Exit codes:
#   0 = all prerequisites met
#   1 = missing prerequisite

RESEARCH_DIR="${1:-}"
ERRORS=()

# --- Check gh CLI ---
if ! command -v gh &>/dev/null; then
  ERRORS+=("ERROR: GitHub CLI (gh) is not installed. Install: https://cli.github.com/")
else
  if ! gh auth status &>/dev/null 2>&1; then
    ERRORS+=("ERROR: GitHub CLI is not authenticated. Run: gh auth login")
  else
    echo "OK: gh CLI installed and authenticated"
  fi
fi

# --- Check git repo with GitHub remote ---
if ! git rev-parse --is-inside-work-tree &>/dev/null 2>&1; then
  ERRORS+=("ERROR: Not inside a git repository")
else
  REMOTE_URL=$(git remote get-url origin 2>/dev/null || echo "")
  if [[ -z "$REMOTE_URL" ]]; then
    ERRORS+=("ERROR: No 'origin' remote configured")
  elif [[ "$REMOTE_URL" != *"github.com"* && "$REMOTE_URL" != *"github:"* ]]; then
    ERRORS+=("WARNING: Remote may not be GitHub: $REMOTE_URL")
  else
    REPO=$(gh repo view --json nameWithOwner -q '.nameWithOwner' 2>/dev/null || echo "")
    if [[ -n "$REPO" ]]; then
      echo "OK: GitHub repo detected: $REPO"
    else
      ERRORS+=("ERROR: Could not determine GitHub repo from remote")
    fi
  fi
fi

# --- Check research directory ---
if [[ -z "$RESEARCH_DIR" ]]; then
  ERRORS+=("ERROR: No research directory specified. Usage: validate-prerequisites.sh <research-dir>")
elif [[ ! -d "$RESEARCH_DIR" ]]; then
  ERRORS+=("ERROR: Research directory does not exist: $RESEARCH_DIR")
else
  echo "OK: Research directory exists: $RESEARCH_DIR"

  # Check for expected files
  FOUND_FILES=0
  EXPECTED_FILES=(
    "RESEARCH-REPORT.md"
  )
  EXPECTED_DIRS=(
    "synthesis"
    "analysis"
  )

  for f in "${EXPECTED_FILES[@]}"; do
    if [[ -f "$RESEARCH_DIR/$f" ]]; then
      FOUND_FILES=$((FOUND_FILES + 1))
      echo "OK: Found $f"
    else
      ERRORS+=("WARNING: Missing expected file: $f")
    fi
  done

  for d in "${EXPECTED_DIRS[@]}"; do
    if [[ -d "$RESEARCH_DIR/$d" ]]; then
      FOUND_FILES=$((FOUND_FILES + 1))
      echo "OK: Found $d/"
    else
      ERRORS+=("WARNING: Missing expected directory: $d/")
    fi
  done

  # List all markdown files found
  MD_COUNT=$(find "$RESEARCH_DIR" -name "*.md" -type f | wc -l)
  echo "INFO: Found $MD_COUNT markdown files in research directory"
fi

# --- Report errors ---
if [[ ${#ERRORS[@]} -gt 0 ]]; then
  echo ""
  echo "=== Issues Found ==="
  for err in "${ERRORS[@]}"; do
    echo "  $err"
  done

  # Check if any are hard errors (not warnings)
  HAS_ERROR=false
  for err in "${ERRORS[@]}"; do
    if [[ "$err" == ERROR:* ]]; then
      HAS_ERROR=true
      break
    fi
  done

  if $HAS_ERROR; then
    echo ""
    echo "RESULT: FAIL — fix errors above before proceeding"
    exit 1
  else
    echo ""
    echo "RESULT: PASS with warnings"
    exit 0
  fi
fi

echo ""
echo "RESULT: PASS — all prerequisites met"
exit 0
