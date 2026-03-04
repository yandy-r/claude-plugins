#!/usr/bin/env bash
# Parse parallel-plan.md and extract task dependencies
# Usage: parse-dependencies.sh <path-to-parallel-plan.md>
#
# Output format (one task per line):
#   TASK_ID|TASK_TITLE|DEPENDENCIES
#
# Examples:
#   1.1|Create user model|none
#   1.2|Add validation|1.1
#   2.1|Setup routes|1.1,1.2
#
# Supports monorepo configurations via .plans-config file.
# See resolve-plans-dir.sh for configuration options.

set -euo pipefail

PLAN_FILE="${1:-}"

# Source the shared resolver for consistency
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="${SCRIPT_DIR}/../../../scripts"

if [[ -f "${SHARED_DIR}/resolve-plans-dir.sh" ]]; then
  # shellcheck source=../../../scripts/resolve-plans-dir.sh
  source "${SHARED_DIR}/resolve-plans-dir.sh" 2>/dev/null || true
fi

if [[ -z "$PLAN_FILE" ]]; then
  echo "Usage: parse-dependencies.sh <path-to-parallel-plan.md>" >&2
  exit 1
fi

if [[ ! -f "$PLAN_FILE" ]]; then
  echo "ERROR: File not found: $PLAN_FILE" >&2
  exit 1
fi

# Extract tasks and their dependencies
# Pattern: #### Task X.Y: [Title] Depends on [deps]

awk '
/^#### Task [0-9]+\.[0-9]+:/ {
  line = $0

  # Extract task ID
  task_id = line
  task_pos = index(task_id, "Task ")
  if (task_pos > 0) {
    task_id = substr(task_id, task_pos + 5)
    colon_pos = index(task_id, ":")
    if (colon_pos > 0) {
      task_id = substr(task_id, 1, colon_pos - 1)
    }
  } else {
    gsub(/.*Task /, "", task_id)
    gsub(/:.*/, "", task_id)
  }
  gsub(/[[:space:]]/, "", task_id)

  # Extract title (between : and Depends)
  title = line
  gsub(/.*Task [0-9]+\.[0-9]+: /, "", title)
  gsub(/ Depends on.*/, "", title)

  # Extract dependencies
  deps = "none"
  depends_pos = index(line, "Depends on [")
  if (depends_pos > 0) {
    deps = substr(line, depends_pos + 12)
    bracket_pos = index(deps, "]")
    if (bracket_pos > 0) {
      deps = substr(deps, 1, bracket_pos - 1)
    }
    if (deps == "") deps = "none"
  }

  gsub(/, */, ",", deps)

  print task_id "|" title "|" deps
}
' "$PLAN_FILE" | while IFS='|' read -r task_id title deps; do
  task_id=$(echo "$task_id" | tr -d ' ')
  title=$(echo "$title" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  deps=$(echo "$deps" | tr -d ' ')

  if [[ -n "$task_id" && "$task_id" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "${task_id}|${title}|${deps}"
  fi
done

# Fallback parsing if awk doesn't work well
if [[ $(grep -c "^#### Task" "$PLAN_FILE") -gt 0 ]] && [[ -z "$(awk '/^#### Task/ {print}' "$PLAN_FILE" 2>/dev/null)" ]]; then
  grep "^#### Task" "$PLAN_FILE" | while read -r line; do
    task_id=$(echo "$line" | sed -E 's/.*Task ([0-9]+\.[0-9]+):.*/\1/')
    title=$(echo "$line" | sed -E 's/.*Task [0-9]+\.[0-9]+: ([^D]*) Depends.*/\1/' | sed 's/[[:space:]]*$//')

    if echo "$line" | grep -q "Depends on \[none\]"; then
      deps="none"
    else
      deps=$(echo "$line" | sed -E 's/.*Depends on \[([^\]]*)\].*/\1/' | tr -d ' ')
    fi

    echo "${task_id}|${title}|${deps}"
  done
fi
