#!/usr/bin/env bash
# setup-worktree.sh — create a parent or child git worktree for a feature run.
#
# Usage:
#   setup-worktree.sh parent <repo-name> <feature-slug>
#   setup-worktree.sh child  <repo-name> <feature-slug> <task-id>
#
# Modes:
#   parent  Creates ~/.claude-worktrees/<repo>-<feature>/ on branch feat/<feature>.
#           Base ref is HEAD of the current branch (wherever the caller stands).
#
#   child   Creates ~/.claude-worktrees/<repo>-<feature>-<task-id>/ on branch
#           feat/<feature>-<task-id>. Base ref is the parent branch feat/<feature>,
#           which must already exist.
#
# Task-id normalisation: dots are replaced with hyphens (e.g. "1.1" → "1-1").
#
# Idempotency: if the target path already exists the script checks whether the
# registered worktree is on the expected branch. If yes it echoes the path and
# exits 0. If no it prints an error to stderr and exits 1.
#
# Exit codes:
#   0  success (path echoed to stdout)
#   1  error (message on stderr)

set -euo pipefail

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat >&2 <<'EOF'
Usage:
  setup-worktree.sh parent <repo-name> <feature-slug>
  setup-worktree.sh child  <repo-name> <feature-slug> <task-id>

Arguments:
  repo-name     Short name of the repository (e.g. "claude-plugins")
  feature-slug  Kebab-case feature identifier (e.g. "add-widget")
  task-id       Parallel-task identifier; dots are normalised to hyphens
                (e.g. "1.1" → "1-1")

Worktree locations:
  parent  ~/.claude-worktrees/<repo>-<feature>/
  child   ~/.claude-worktrees/<repo>-<feature>-<task-id>/

Branches:
  parent  feat/<feature>          (branched from HEAD)
  child   feat/<feature>-<task-id> (branched from feat/<feature>)

The script is idempotent: if the worktree already exists and is on the
expected branch it simply echoes the path and exits 0.
EOF
}

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

_error() {
  echo "setup-worktree.sh: error: $*" >&2
}

# Replace every '.' with '-' in a task-id string.
normalize_task_id() {
  local raw="$1"
  echo "${raw//./-}"
}

# Return the branch currently checked out in a worktree path.
# Uses `git worktree list --porcelain` output.
_worktree_branch() {
  local path="$1"
  git worktree list --porcelain 2>/dev/null | awk -v p="$path" '
    /^worktree / { cur = substr($0, 10) }
    /^branch /   { if (cur == p) { print substr($0, 8); exit } }
  '
}

# ---------------------------------------------------------------------------
# Mode: parent
# ---------------------------------------------------------------------------

setup_parent() {
  local repo_name="$1"
  local feature_slug="$2"

  if [[ -z "$repo_name" || -z "$feature_slug" ]]; then
    _error "repo-name and feature-slug must not be empty"
    usage
    exit 1
  fi

  local worktrees_dir="${HOME}/.claude-worktrees"
  local parent_path="${worktrees_dir}/${repo_name}-${feature_slug}"
  local branch="feat/${feature_slug}"

  # Ensure the worktrees directory exists.
  mkdir -p "$worktrees_dir"

  # Idempotency: path already exists.
  if [[ -d "$parent_path" ]]; then
    local actual_branch
    actual_branch="$(_worktree_branch "$parent_path")"

    # Normalise: git stores refs as "refs/heads/<branch>"
    local expected_ref="refs/heads/${branch}"
    if [[ "$actual_branch" == "$expected_ref" || "$actual_branch" == "$branch" ]]; then
      echo "$parent_path"
      return 0
    else
      _error "worktree already exists at '$parent_path' but is on branch '${actual_branch}' (expected '${expected_ref}')"
      exit 1
    fi
  fi

  # Create the parent worktree branching from HEAD.
  git worktree add -B "$branch" "$parent_path" HEAD

  echo "$parent_path"
}

# ---------------------------------------------------------------------------
# Mode: child
# ---------------------------------------------------------------------------

setup_child() {
  local repo_name="$1"
  local feature_slug="$2"
  local raw_task_id="$3"

  if [[ -z "$repo_name" || -z "$feature_slug" || -z "$raw_task_id" ]]; then
    _error "repo-name, feature-slug, and task-id must not be empty"
    usage
    exit 1
  fi

  local task_id
  task_id="$(normalize_task_id "$raw_task_id")"

  local worktrees_dir="${HOME}/.claude-worktrees"
  local child_path="${worktrees_dir}/${repo_name}-${feature_slug}-${task_id}"
  local branch="feat/${feature_slug}-${task_id}"
  local parent_branch="feat/${feature_slug}"

  # Ensure the parent branch exists before attempting child creation.
  if ! git rev-parse --verify "refs/heads/${parent_branch}" >/dev/null 2>&1; then
    _error "parent branch '${parent_branch}' does not exist; create the parent worktree first"
    exit 1
  fi

  # Ensure the worktrees directory exists.
  mkdir -p "$worktrees_dir"

  # Idempotency: path already exists.
  if [[ -d "$child_path" ]]; then
    local actual_branch
    actual_branch="$(_worktree_branch "$child_path")"

    local expected_ref="refs/heads/${branch}"
    if [[ "$actual_branch" == "$expected_ref" || "$actual_branch" == "$branch" ]]; then
      echo "$child_path"
      return 0
    else
      _error "worktree already exists at '$child_path' but is on branch '${actual_branch}' (expected '${expected_ref}')"
      exit 1
    fi
  fi

  # Create the child worktree branching from the parent branch.
  git worktree add -B "$branch" "$child_path" "$parent_branch"

  echo "$child_path"
}

# ---------------------------------------------------------------------------
# Entry point
# ---------------------------------------------------------------------------

main() {
  case "${1:-}" in
    parent)
      shift
      if [[ $# -ne 2 ]]; then
        _error "'parent' mode requires exactly 2 arguments: <repo-name> <feature-slug>"
        usage
        exit 1
      fi
      setup_parent "$1" "$2"
      ;;
    child)
      shift
      if [[ $# -ne 3 ]]; then
        _error "'child' mode requires exactly 3 arguments: <repo-name> <feature-slug> <task-id>"
        usage
        exit 1
      fi
      setup_child "$1" "$2" "$3"
      ;;
    --help|-h)
      usage
      exit 0
      ;;
    *)
      _error "first argument must be 'parent' or 'child'"
      usage
      exit 1
      ;;
  esac
}

main "$@"
