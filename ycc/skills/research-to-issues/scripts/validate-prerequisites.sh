#!/usr/bin/env bash
set -euo pipefail

# Validate prerequisites for research-to-issues skill
# Usage: validate-prerequisites.sh <source-path> [--type TYPE]
#
# Supports multiple source types:
#   deep-research  - Directory with RESEARCH-REPORT.md
#   feature-spec   - feature-spec.md file
#   parallel-plan  - parallel-plan.md file
#   prp-plan       - *.plan.md file
#
# Auto-detects type from path/content if --type is not specified.
#
# Checks:
#   1. gh CLI is installed and authenticated
#   2. Current directory is a git repo with a GitHub remote
#   3. Source path exists and matches expected structure
#
# Exit codes:
#   0 = all prerequisites met
#   1 = missing prerequisite

SOURCE_PATH="${1:-}"
EXPLICIT_TYPE=""
DETECTED_TYPE=""
ERRORS=()

# Parse optional --type flag
shift || true
while [[ $# -gt 0 ]]; do
  case "$1" in
    --type)
      EXPLICIT_TYPE="${2:-}"
      shift 2 || true
      ;;
    *)
      shift
      ;;
  esac
done

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

# --- Check source path ---
if [[ -z "$SOURCE_PATH" ]]; then
  ERRORS+=("ERROR: No source path specified. Usage: validate-prerequisites.sh <source-path> [--type TYPE]")
else
  # --- Auto-detect source type ---
  if [[ -n "$EXPLICIT_TYPE" ]]; then
    DETECTED_TYPE="$EXPLICIT_TYPE"
    echo "OK: Using explicit type: $DETECTED_TYPE"
  elif [[ -d "$SOURCE_PATH" ]]; then
    # Directory: check for deep-research structure
    if [[ -f "$SOURCE_PATH/RESEARCH-REPORT.md" ]]; then
      DETECTED_TYPE="deep-research"
    elif [[ -f "$SOURCE_PATH/deep-research-report.md" ]]; then
      DETECTED_TYPE="deep-research"
    elif ls "$SOURCE_PATH"/*research*report*.md &>/dev/null 2>&1; then
      DETECTED_TYPE="deep-research"
    else
      ERRORS+=("ERROR: Directory does not contain a research report file (RESEARCH-REPORT.md or deep-research-report.md): $SOURCE_PATH")
    fi
  elif [[ -f "$SOURCE_PATH" ]]; then
    # File: detect by filename pattern
    BASENAME=$(basename "$SOURCE_PATH")
    if [[ "$BASENAME" == "feature-spec.md" ]]; then
      DETECTED_TYPE="feature-spec"
    elif [[ "$BASENAME" == "parallel-plan.md" ]]; then
      DETECTED_TYPE="parallel-plan"
    elif [[ "$BASENAME" == *.plan.md ]]; then
      DETECTED_TYPE="prp-plan"
    else
      # Content-based fallback: check first 40 lines for signature headers
      HEAD_CONTENT=$(head -40 "$SOURCE_PATH" 2>/dev/null || echo "")
      if echo "$HEAD_CONTENT" | grep -q "## Critically Relevant Files"; then
        DETECTED_TYPE="parallel-plan"
      elif echo "$HEAD_CONTENT" | grep -q "## Mandatory Reading\|## Step-by-Step Tasks"; then
        DETECTED_TYPE="prp-plan"
      elif echo "$HEAD_CONTENT" | grep -q "## Executive Summary"; then
        DETECTED_TYPE="feature-spec"
      else
        ERRORS+=("ERROR: Could not detect source type from file: $BASENAME. Use --type to specify.")
      fi
    fi
  else
    ERRORS+=("ERROR: Source path does not exist: $SOURCE_PATH")
  fi

  # --- Type-specific validation ---
  if [[ -n "$DETECTED_TYPE" ]]; then
    echo "DETECTED_TYPE: $DETECTED_TYPE"

    case "$DETECTED_TYPE" in
      deep-research)
        if [[ ! -d "$SOURCE_PATH" ]]; then
          ERRORS+=("ERROR: deep-research source must be a directory: $SOURCE_PATH")
        else
          echo "OK: Source directory exists: $SOURCE_PATH"
          # Check for expected files (accept multiple naming conventions)
          REPORT_FILE=""
          if [[ -f "$SOURCE_PATH/RESEARCH-REPORT.md" ]]; then
            REPORT_FILE="RESEARCH-REPORT.md"
          elif [[ -f "$SOURCE_PATH/deep-research-report.md" ]]; then
            REPORT_FILE="deep-research-report.md"
          else
            # Glob for any research report variant
            REPORT_FILE=$(ls "$SOURCE_PATH"/*research*report*.md 2>/dev/null | head -1 | xargs -r basename)
          fi
          if [[ -n "$REPORT_FILE" ]]; then
            echo "OK: Found research report: $REPORT_FILE"
          else
            ERRORS+=("ERROR: No research report file found in $SOURCE_PATH")
          fi
          for d in "synthesis" "analysis"; do
            if [[ -d "$SOURCE_PATH/$d" ]]; then
              echo "OK: Found $d/"
            else
              ERRORS+=("WARNING: Missing expected directory: $d/")
            fi
          done
          MD_COUNT=$(find "$SOURCE_PATH" -name "*.md" -type f | wc -l)
          echo "INFO: Found $MD_COUNT markdown files in research directory"
        fi
        ;;
      feature-spec)
        if [[ ! -f "$SOURCE_PATH" ]]; then
          ERRORS+=("ERROR: feature-spec source must be a file: $SOURCE_PATH")
        else
          echo "OK: Source file exists: $SOURCE_PATH"
          if grep -q "## Executive Summary" "$SOURCE_PATH" 2>/dev/null; then
            echo "OK: Contains expected ## Executive Summary header"
          else
            ERRORS+=("WARNING: Missing ## Executive Summary header -- file may not be a valid feature-spec")
          fi
          if grep -q "## Task Breakdown Preview\|## Recommendations" "$SOURCE_PATH" 2>/dev/null; then
            echo "OK: Contains task/recommendation structure"
          else
            ERRORS+=("WARNING: Missing task breakdown or recommendations section")
          fi
        fi
        ;;
      parallel-plan)
        if [[ ! -f "$SOURCE_PATH" ]]; then
          ERRORS+=("ERROR: parallel-plan source must be a file: $SOURCE_PATH")
        else
          echo "OK: Source file exists: $SOURCE_PATH"
          if grep -q "## Critically Relevant Files\|## Implementation Plan" "$SOURCE_PATH" 2>/dev/null; then
            echo "OK: Contains expected parallel-plan structure"
          else
            ERRORS+=("WARNING: Missing expected parallel-plan headers")
          fi
          TASK_COUNT=$(grep -c "^####.*Task" "$SOURCE_PATH" 2>/dev/null) || TASK_COUNT=0
          echo "INFO: Found approximately $TASK_COUNT tasks"
        fi
        ;;
      prp-plan)
        if [[ ! -f "$SOURCE_PATH" ]]; then
          ERRORS+=("ERROR: prp-plan source must be a file: $SOURCE_PATH")
        else
          echo "OK: Source file exists: $SOURCE_PATH"
          if grep -q "## Step-by-Step Tasks\|## Tasks\|## Summary" "$SOURCE_PATH" 2>/dev/null; then
            echo "OK: Contains expected PRP plan structure"
          else
            ERRORS+=("WARNING: Missing expected PRP plan headers")
          fi
          if grep -q "## Batches" "$SOURCE_PATH" 2>/dev/null; then
            echo "INFO: Parallel/batch mode detected"
          else
            echo "INFO: Sequential mode detected"
          fi
          # Detect format variant: standard (### Task N:) or narrative (**TN —)
          if grep -q "^### Task [0-9]" "$SOURCE_PATH" 2>/dev/null; then
            echo "INFO: Standard format detected (### Task N: headings)"
            TASK_COUNT=$(grep -c "^### Task [0-9]" "$SOURCE_PATH" 2>/dev/null) || TASK_COUNT=0
          elif grep -q '^\*\*T[0-9]' "$SOURCE_PATH" 2>/dev/null; then
            echo "INFO: Narrative format detected (**TN bold markers)"
            TASK_COUNT=$(grep -c '^\*\*T[0-9]' "$SOURCE_PATH" 2>/dev/null) || TASK_COUNT=0
          else
            TASK_COUNT=0
          fi
          echo "INFO: Found approximately $TASK_COUNT tasks"
        fi
        ;;
      *)
        ERRORS+=("ERROR: Unknown source type: $DETECTED_TYPE. Valid types: deep-research, feature-spec, parallel-plan, prp-plan")
        ;;
    esac
  fi
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
