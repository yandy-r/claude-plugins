#!/usr/bin/env bash
# Pre-generation gate: blocks plan generation if analysis files are missing.
# Usage: persist-or-fail.sh <feature-dir>
#
# Exit 0 = all analysis files present and non-empty, safe to generate plan
# Exit 1 = prints MISSING_FILES list and ACTION_REQUIRED message
#
# This is the critical chokepoint that runs immediately before plan generation.
# Unlike validate-analysis-artifacts.sh (which checks quality), this script
# is a binary pass/fail gate: files exist and are non-empty, or plan generation
# is blocked.

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RESOLVER="${SCRIPT_DIR}/../../_shared/scripts/resolve-plans-dir.sh"

# Source resolver to get PLANS_ROOT for path resolution
if [[ -f "$RESOLVER" ]]; then
    # shellcheck source=../../_shared/scripts/resolve-plans-dir.sh
    source "$RESOLVER"
fi

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

if [[ $# -lt 1 ]]; then
    echo "Usage: $0 <feature-dir>"
    echo ""
    echo "Pre-generation gate: ensures all analysis files exist before plan generation."
    echo "Exit 0 = proceed to plan generation"
    echo "Exit 1 = analysis files missing, plan generation blocked"
    exit 1
fi

feature_dir="$1"

# Resolve relative paths against PLANS_ROOT (from resolve-plans-dir.sh)
if [[ "$feature_dir" != /* && -n "${PLANS_ROOT:-}" ]]; then
    feature_dir="${PLANS_ROOT}/${feature_dir}"
fi

if [[ ! -d "$feature_dir" ]]; then
    echo -e "${RED}GATE FAILED${NC}: Feature directory not found: $feature_dir"
    exit 1
fi

declare -a required_files=(
    "analysis-context.md"
    "analysis-code.md"
    "analysis-tasks.md"
)

declare -a missing_files=()

for file in "${required_files[@]}"; do
    path="${feature_dir}/${file}"
    if [[ ! -f "$path" ]]; then
        missing_files+=("$file")
    elif [[ ! -s "$path" ]]; then
        missing_files+=("$file (empty)")
    fi
done

if [[ ${#missing_files[@]} -eq 0 ]]; then
    echo -e "${GREEN}GATE PASSED${NC}: All analysis files present in ${feature_dir}"
    for file in "${required_files[@]}"; do
        size=$(wc -c < "${feature_dir}/${file}" | tr -d ' ')
        echo -e "  ${GREEN}OK${NC}: ${file} (${size} bytes)"
    done
    exit 0
else
    echo -e "${RED}GATE FAILED${NC}: Analysis files missing — plan generation BLOCKED"
    echo ""
    echo "MISSING_FILES:"
    for file in "${missing_files[@]}"; do
        echo -e "  ${RED}-${NC} ${file}"
    done
    echo ""
    echo -e "${YELLOW}ACTION_REQUIRED${NC}: Write the missing files to ${feature_dir}/ before proceeding."
    echo "Use content from agent response <ANALYSIS_*> tags, or re-deploy the failed agents."
    echo "Do NOT proceed to plan generation until this gate passes (exit 0)."
    exit 1
fi
