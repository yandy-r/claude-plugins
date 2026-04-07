#!/usr/bin/env bash
# Check prerequisites for deep research skill

set -euo pipefail

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Usage function
usage() {
    cat << EOF
Usage: $(basename "$0") OUTPUT_DIR

Check prerequisites for deep research execution.

Arguments:
    OUTPUT_DIR    The output directory for research artifacts

Example:
    $(basename "$0") research/ai-deployment
EOF
    exit 1
}

# Check if output directory is provided
if [ $# -eq 0 ]; then
    usage
fi

OUTPUT_DIR="$1"

echo "Checking prerequisites for deep research..."
echo ""

# Track overall status
ERRORS=0
WARNINGS=0

# Check if output directory exists
if [ -d "$OUTPUT_DIR" ]; then
    echo -e "${YELLOW}⚠ Warning:${NC} Output directory already exists: $OUTPUT_DIR"
    echo "  Existing files may be overwritten."
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC} Output directory does not exist (will be created)"
fi

# Check if required directories can be created
PARENT_DIR=$(dirname "$OUTPUT_DIR")
if [ ! -d "$PARENT_DIR" ]; then
    echo -e "${RED}✗ Error:${NC} Parent directory does not exist: $PARENT_DIR"
    echo "  Please create the parent directory first."
    ERRORS=$((ERRORS + 1))
elif [ ! -w "$PARENT_DIR" ]; then
    echo -e "${RED}✗ Error:${NC} Parent directory is not writable: $PARENT_DIR"
    ERRORS=$((ERRORS + 1))
else
    echo -e "${GREEN}✓${NC} Parent directory exists and is writable"
fi

# Check for required tools
echo ""
echo "Checking for required tools..."

check_command() {
    local cmd=$1
    local required=${2:-yes}

    if command -v "$cmd" &> /dev/null; then
        echo -e "${GREEN}✓${NC} $cmd found: $(command -v "$cmd")"
    else
        if [ "$required" = "yes" ]; then
            echo -e "${RED}✗ Error:${NC} $cmd not found (required)"
            ERRORS=$((ERRORS + 1))
        else
            echo -e "${YELLOW}⚠ Warning:${NC} $cmd not found (optional)"
            WARNINGS=$((WARNINGS + 1))
        fi
    fi
}

# Required commands
check_command "mkdir" "yes"
check_command "cat" "yes"
check_command "ls" "yes"

# Optional but recommended
check_command "rg" "no"
check_command "fd" "no"

# Check disk space
echo ""
echo "Checking disk space..."
AVAILABLE_KB=$(df -k "$PARENT_DIR" | awk 'NR==2 {print $4}')
AVAILABLE_MB=$((AVAILABLE_KB / 1024))

if [ "$AVAILABLE_MB" -lt 10 ]; then
    echo -e "${RED}✗ Error:${NC} Insufficient disk space: ${AVAILABLE_MB}MB available"
    echo "  At least 10MB recommended for research artifacts"
    ERRORS=$((ERRORS + 1))
elif [ "$AVAILABLE_MB" -lt 50 ]; then
    echo -e "${YELLOW}⚠ Warning:${NC} Low disk space: ${AVAILABLE_MB}MB available"
    echo "  50MB+ recommended for comprehensive research"
    WARNINGS=$((WARNINGS + 1))
else
    echo -e "${GREEN}✓${NC} Sufficient disk space: ${AVAILABLE_MB}MB available"
fi

# Summary
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
if [ $ERRORS -eq 0 ] && [ $WARNINGS -eq 0 ]; then
    echo -e "${GREEN}✓ All prerequisites met!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    exit 0
elif [ $ERRORS -eq 0 ]; then
    echo -e "${YELLOW}⚠ Prerequisites met with warnings:${NC}"
    echo "  - Warnings: $WARNINGS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "You can proceed, but review warnings above."
    exit 0
else
    echo -e "${RED}✗ Prerequisites not met:${NC}"
    echo "  - Errors: $ERRORS"
    echo "  - Warnings: $WARNINGS"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "Please fix errors above before proceeding."
    exit 1
fi
