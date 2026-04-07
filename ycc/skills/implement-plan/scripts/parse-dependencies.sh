#!/usr/bin/env bash
# Parse parallel-plan.md and extract task dependencies
# Usage: parse-dependencies.sh <path-to-parallel-plan.md>
#
# Output format (one task per line):
#   TASK_ID|TASK_TITLE|DEPENDENCIES
#
# Supports two task ID formats:
#   Format A (decimal):  #### Task 1.1: Title Depends on [none]
#   Format B (T-prefix): #### Task T0: Title
#                         - **Dependencies**: None
#
# Examples:
#   1.1|Create user model|none
#   T0|Create user model|none
#   T1|Add validation|T0
#   2.1|Setup routes|1.1,1.2
#
# Supports monorepo configurations via .plans-config file.
# See resolve-plans-dir.sh for configuration options.

set -euo pipefail

PLAN_FILE="${1:-}"

# Source the shared resolver for consistency
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SHARED_DIR="${SCRIPT_DIR}/../../_shared/scripts"

if [[ -f "${SHARED_DIR}/resolve-plans-dir.sh" ]]; then
  # shellcheck source=../../_shared/scripts/resolve-plans-dir.sh
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

# Extract tasks and their dependencies using a state machine.
# Handles both inline deps (Format A) and multi-line deps (Format B).
#
# State machine:
#   - On task header: flush any pending task, start new pending task
#   - On dependency line: attach deps to pending task, flush it
#   - On EOF: flush any remaining pending task

awk '
function flush_pending() {
  if (pending_id != "") {
    # Normalize "None" -> "none" (case-insensitive)
    if (tolower(pending_deps) == "none" || pending_deps == "") {
      pending_deps = "none"
    }
    gsub(/, */, ",", pending_deps)
    gsub(/ /, "", pending_deps)
    print pending_id "|" pending_title "|" pending_deps
    pending_id = ""
    pending_title = ""
    pending_deps = ""
  }
}

BEGIN {
  pending_id = ""
  pending_title = ""
  pending_deps = ""
}

/^#### Task ([0-9]+\.[0-9]+|T[0-9]+):/ {
  # Flush any previous pending task (had no inline or multi-line deps)
  flush_pending()

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
  }
  gsub(/[[:space:]]/, "", task_id)

  # Extract title (between "Task ID: " and either "Depends on" or end of line)
  title = line
  sub(".*Task " task_id ": *", "", title)
  gsub(/ Depends on.*/, "", title)
  # Trim whitespace
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", title)

  # Check for inline dependencies (Format A)
  deps = "none"
  depends_pos = index(line, "Depends on [")
  if (depends_pos > 0) {
    deps = substr(line, depends_pos + 12)
    bracket_pos = index(deps, "]")
    if (bracket_pos > 0) {
      deps = substr(deps, 1, bracket_pos - 1)
    }
    if (deps == "") deps = "none"
    # Inline deps found — emit immediately
    gsub(/, */, ",", deps)
    if (tolower(deps) == "none") deps = "none"
    print task_id "|" title "|" deps
    next
  }

  # No inline deps — store as pending for multi-line resolution
  pending_id = task_id
  pending_title = title
  pending_deps = ""
  next
}

# Multi-line dependency pattern: - **Dependencies**: T0, T1
pending_id != "" && /^- \*\*Dependencies\*\*:/ {
  dep_line = $0
  sub(/.*\*\*Dependencies\*\*: */, "", dep_line)
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", dep_line)
  pending_deps = dep_line
  flush_pending()
  next
}

END {
  flush_pending()
}
' "$PLAN_FILE" | while IFS='|' read -r task_id title deps; do
  task_id=$(echo "$task_id" | tr -d ' ')
  title=$(echo "$title" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  deps=$(echo "$deps" | tr -d ' ')

  if [[ -n "$task_id" && "$task_id" =~ ^([0-9]+\.[0-9]+|T[0-9]+)$ ]]; then
    echo "${task_id}|${title}|${deps}"
  fi
done
