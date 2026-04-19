#!/usr/bin/env bash
# Merge child worktrees back into the parent worktree after a parallel batch completes.
# Usage: merge-children.sh <repo-name> <feature-slug> <task-id>[,<task-id>,...]
#
# Arguments:
#   repo-name     Name of the repository (e.g. claude-plugins)
#   feature-slug  Feature slug used in branch and worktree names (e.g. add-widget)
#   task-id       Comma-separated list of task IDs to merge (e.g. 1.1,1.2,1.3)
#                 Dots are normalized to hyphens (1.1 -> 1-1)
#
# For each task-id:
#   - Merges feat/<feature-slug>-<task-id> into the parent branch (--no-ff)
#   - On success: removes child worktree + deletes child branch
#   - On conflict: aborts the merge, prints CONFLICT to stderr, exits 1 immediately
#   - If child branch/worktree not found: prints SKIP to stderr, continues
#
# Exit codes:
#   0 - All task-ids merged or skipped without conflict
#   1 - A merge conflict was encountered (caller must resolve manually)

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

usage() {
  cat >&2 <<'EOF'
Usage: merge-children.sh <repo-name> <feature-slug> <task-id>[,<task-id>,...]

Arguments:
  repo-name     Repository name (e.g. my-repo)
  feature-slug  Feature slug used in branch/worktree names (e.g. add-widget)
  task-id       Comma-separated task IDs to merge (e.g. 1.1,1.2,1.3)
                Dots are normalized to hyphens automatically (1.1 -> 1-1)

Behavior:
  - Resolves parent worktree at ~/.claude-worktrees/<repo>-<feature>/
  - Verifies parent is on branch feat/<feature>
  - For each task-id, merges feat/<feature>-<task-id> with --no-ff
  - On success:  removes child worktree and deletes child branch
  - On conflict: aborts merge, prints CONFLICT to stderr, exits 1 immediately
  - Missing branch/worktree: prints SKIP to stderr, continues

Exit codes:
  0  All task-ids merged or skipped without conflict
  1  Merge conflict encountered (manual resolution required)
EOF
  exit 1
}

# Normalize a task ID: replace dots with hyphens (e.g. 1.1 -> 1-1)
normalize_task_id() {
  local raw="$1"
  echo "${raw//./-}"
}

# ---------------------------------------------------------------------------
# Per-task merge logic
# ---------------------------------------------------------------------------

merge_one() {
  local task_id="$1"           # already normalized (dots -> hyphens)
  local parent_path="$2"
  local feature_slug="$3"
  local repo_name="$4"

  local child_branch="feat/${feature_slug}-${task_id}"
  local child_path="${HOME}/.claude-worktrees/${repo_name}-${feature_slug}-${task_id}"

  # Check whether the child branch exists in the repo
  if ! git -C "${parent_path}" rev-parse --verify "${child_branch}" >/dev/null 2>&1; then
    echo "SKIP: ${task_id} (branch not found)" >&2
    return 0
  fi

  # Attempt the merge inside the parent worktree
  if git -C "${parent_path}" merge --no-ff "${child_branch}"; then
    # Success — clean up child worktree and branch
    if [[ -d "${child_path}" ]]; then
      if ! git -C "${parent_path}" worktree remove --force "${child_path}" 2>/dev/null; then
        echo "WARN: worktree remove failed for ${task_id} at ${child_path}" >&2
      fi
    fi
    if ! git -C "${parent_path}" branch -d "${child_branch}" 2>/dev/null; then
      echo "WARN: branch delete failed for ${task_id}: ${child_branch}" >&2
    fi
    echo "MERGED: ${task_id}"
  else
    # Conflict — abort and fail immediately
    git -C "${parent_path}" merge --abort 2>/dev/null || true
    echo "CONFLICT: ${task_id} at ${child_path}" >&2
    exit 1
  fi
}

# ---------------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------------

main() {
  # Require exactly 3 positional arguments
  if [[ $# -ne 3 ]]; then
    echo "ERROR: expected 3 arguments, got $#" >&2
    usage
  fi

  local repo_name="$1"
  local feature_slug="$2"
  local raw_task_ids="$3"

  # Reject empty strings
  if [[ -z "${repo_name}" ]]; then
    echo "ERROR: repo-name must not be empty" >&2
    usage
  fi
  if [[ -z "${feature_slug}" ]]; then
    echo "ERROR: feature-slug must not be empty" >&2
    usage
  fi
  if [[ -z "${raw_task_ids}" ]]; then
    echo "ERROR: task-id list must not be empty" >&2
    usage
  fi

  local parent_path="${HOME}/.claude-worktrees/${repo_name}-${feature_slug}"
  local expected_branch="feat/${feature_slug}"

  # Verify parent worktree exists
  if [[ ! -d "${parent_path}" ]]; then
    echo "ERROR: parent worktree not found: ${parent_path}" >&2
    exit 1
  fi

  # Verify parent worktree is a valid git worktree on the expected branch
  if ! git -C "${parent_path}" rev-parse --git-dir >/dev/null 2>&1; then
    echo "ERROR: ${parent_path} is not a valid git worktree" >&2
    exit 1
  fi

  local current_branch
  current_branch=$(git -C "${parent_path}" rev-parse --abbrev-ref HEAD 2>/dev/null || true)

  if [[ "${current_branch}" != "${expected_branch}" ]]; then
    echo "ERROR: parent worktree is on branch '${current_branch}', expected '${expected_branch}'" >&2
    exit 1
  fi

  # Split task IDs on commas and process each one
  local task_id_entry
  IFS=',' read -ra task_id_entries <<< "${raw_task_ids}"

  for task_id_entry in "${task_id_entries[@]}"; do
    # Trim whitespace
    task_id_entry="${task_id_entry#"${task_id_entry%%[![:space:]]*}"}"
    task_id_entry="${task_id_entry%"${task_id_entry##*[![:space:]]}"}"

    if [[ -z "${task_id_entry}" ]]; then
      continue
    fi

    local task_id
    task_id=$(normalize_task_id "${task_id_entry}")

    merge_one "${task_id}" "${parent_path}" "${feature_slug}" "${repo_name}"
    # Note: merge_one exits 1 on conflict, so we only reach here on success or skip
  done

  exit 0
}

main "$@"
