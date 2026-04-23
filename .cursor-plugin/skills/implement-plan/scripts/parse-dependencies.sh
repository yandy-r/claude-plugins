#!/usr/bin/env bash
# Parse parallel-plan.md and extract task dependencies plus optional worktree paths.
# Usage: parse-dependencies.sh <path-to-parallel-plan.md>
#
# Output format (one task per line):
#   TASK_ID|TASK_TITLE|DEPENDENCIES|WORKTREE_PATH
#
# The WORKTREE_PATH field is populated when the task block contains a
# "- **Worktree**:" line (optional). Legacy per-task paths may still appear; the
# single worktree contract does not require per-task lines — the fourth field may
# be empty for all tasks when the plan only has `## Worktree Setup` with **Parent**.
# Sequential tasks and plans produced without per-task worktree output have an
# empty fourth field, preserving back-compatibility with callers that only read
# the first three fields.
#
# Additionally, two header lines are emitted BEFORE the task rows when a
# "## Worktree Setup" section is detected in the plan (only **Parent** is required
# for the single-worktree contract; a **Children** list is not required):
#   WT_PARENT_PATH=<path>
#   WT_FEATURE_SLUG=<slug>
#
# When no "## Worktree Setup" section is present, neither header line is emitted
# (back-compat: the output is identical to the pre-worktree format).
#
# Supports two task ID formats:
#   Format A (decimal):  #### Task 1.1: Title Depends on [none]
#   Format B (T-prefix): #### Task T0: Title
#                         - **Dependencies**: None
#
# Examples (no annotations):
#   1.1|Create user model|none|
#   T0|Create user model|none|
#   T1|Add validation|T0|
#   2.1|Setup routes|1.1,1.2|
#
# Examples (with legacy per-task worktree lines):
#   WT_PARENT_PATH=~/.claude-worktrees/myrepo-my-feature/
#   WT_FEATURE_SLUG=myrepo-my-feature
#   1.1|Create user model|none|~/.claude-worktrees/myrepo-my-feature-1-1/
#   1.2|Add validation|none|~/.claude-worktrees/myrepo-my-feature-1-2/
#   2.1|Setup routes|1.1,1.2|
#
# Examples (single worktree / ## Worktree Setup + **Parent** only; per-task
#   **Worktree** lines omitted; fourth field empty for each task):
#   WT_PARENT_PATH=~/.claude-worktrees/myrepo-my-feature/
#   WT_FEATURE_SLUG=myrepo-my-feature
#   1.1|Create user model|none|
#   1.2|Add validation|none|
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

# ─────────────────────────────────────────────────────────────────────────────
# Pass 1 — Extract optional ## Worktree Setup header (parent path + slug).
# Emits WT_PARENT_PATH= and WT_FEATURE_SLUG= lines when the section is present.
# ─────────────────────────────────────────────────────────────────────────────
awk '
/^## Worktree Setup/ { in_wt_setup = 1; next }
# Stop at the next ## heading
in_wt_setup && /^## / { in_wt_setup = 0; next }
# Match: - **Parent**: ~/.claude-worktrees/<repo>-<feature>/   (branch: ...)
in_wt_setup && /^\- \*\*Parent\*\*:/ {
  line = $0
  sub(/.*\*\*Parent\*\*: */, "", line)
  # Strip trailing "  (branch: ...)" annotation if present
  sub(/ *(branch:.*|\(branch:.*)?$/, "", line)
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", line)
  parent_path = line
  # Derive feature slug from the last path component, stripping trailing slash
  slug = parent_path
  gsub(/\/$/, "", slug)
  n = split(slug, parts, "/")
  slug = parts[n]
  # Strip leading "<repo>-" prefix: everything up to and including the first "-"
  # The convention is <repo>-<feature>; we want just <feature>.
  # Use the last component directly as the slug — callers can derive repo separately.
  print "WT_PARENT_PATH=" parent_path
  print "WT_FEATURE_SLUG=" slug
  found = 1
}
' "$PLAN_FILE"

# ─────────────────────────────────────────────────────────────────────────────
# Pass 2 — Extract tasks and their dependencies using a state machine.
# Handles both inline deps (Format A) and multi-line deps (Format B).
# Also captures per-task **Worktree**: lines (Format C, optional).
#
# State machine:
#   - On task header: flush any pending task, start new pending task
#   - On dependency line: attach deps to pending task
#   - On worktree line: attach worktree path to pending task
#   - On EOF: flush any remaining pending task
# ─────────────────────────────────────────────────────────────────────────────
awk '
function flush_pending() {
  if (pending_id != "") {
    # Normalize "None" -> "none" (case-insensitive)
    if (tolower(pending_deps) == "none" || pending_deps == "") {
      pending_deps = "none"
    }
    gsub(/, */, ",", pending_deps)
    gsub(/ /, "", pending_deps)
    print pending_id "|" pending_title "|" pending_deps "|" pending_wt
    pending_id = ""
    pending_title = ""
    pending_deps = ""
    pending_wt = ""
  }
}

BEGIN {
  pending_id = ""
  pending_title = ""
  pending_deps = ""
  pending_wt = ""
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
    # Inline deps found — store in pending (worktree may follow on next lines)
    gsub(/, */, ",", deps)
    if (tolower(deps) == "none") deps = "none"
    pending_id = task_id
    pending_title = title
    pending_deps = deps
    pending_wt = ""
    next
  }

  # No inline deps — store as pending for multi-line resolution
  pending_id = task_id
  pending_title = title
  pending_deps = ""
  pending_wt = ""
  next
}

# Multi-line dependency pattern: - **Dependencies**: T0, T1
pending_id != "" && /^- \*\*Dependencies\*\*:/ {
  dep_line = $0
  sub(/.*\*\*Dependencies\*\*: */, "", dep_line)
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", dep_line)
  pending_deps = dep_line
  # Do NOT flush here — worktree line may still follow
  next
}

# Per-task worktree annotation: - **Worktree**: <path>   (branch: ...)
pending_id != "" && /^- \*\*Worktree\*\*:/ {
  wt_line = $0
  sub(/.*\*\*Worktree\*\*: */, "", wt_line)
  # Strip trailing "(branch: ...)" annotation if present
  sub(/ *(branch:.*|\(branch:.*)?$/, "", wt_line)
  gsub(/^[[:space:]]+|[[:space:]]+$/, "", wt_line)
  pending_wt = wt_line
  # Flush now — worktree line is typically the last field in a task block
  flush_pending()
  next
}

# Next task header will flush the previous pending — but if a task with
# multi-line deps has no worktree annotation we flush in flush_pending() at EOF.
# Also flush when we see a new top-level heading that is NOT a task header.
/^## / || /^### / {
  flush_pending()
  next
}

END {
  flush_pending()
}
' "$PLAN_FILE" | while IFS='|' read -r task_id title deps wt; do
  task_id=$(echo "$task_id" | tr -d ' ')
  title=$(echo "$title" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
  deps=$(echo "$deps" | tr -d ' ')
  # wt may be empty or contain a path — preserve as-is (trim only)
  wt=$(echo "$wt" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')

  if [[ -n "$task_id" && "$task_id" =~ ^([0-9]+\.[0-9]+|T[0-9]+)$ ]]; then
    echo "${task_id}|${title}|${deps}|${wt}"
  fi
done
