#!/usr/bin/env bash
# setup-worktree.sh — create a parent or child git worktree for a feature run.
#
# Usage:
#   setup-worktree.sh parent <repo-name> <feature-slug> [--base-ref <branch>]
#   setup-worktree.sh child  <repo-name> <feature-slug> <task-id>
#
# Modes:
#   parent  Creates ~/.claude-worktrees/<repo>-<feature>/.
#           Default base ref: HEAD of the current branch (wherever the caller
#           stands); the worktree is placed on a new branch feat/<feature>.
#
#           With --base-ref <branch>: checks out the existing <branch> directly
#           into the worktree — no new branch is created. Useful for reviewing
#           or fixing an existing PR branch in isolation. If <branch> does not
#           resolve locally, the script attempts
#           `git fetch origin <branch>:<branch>` once and retries.
#
#   child   Creates ~/.claude-worktrees/<repo>-<feature>-<task-id>/ on branch
#           feat/<feature>-<task-id>. Base ref is the parent branch feat/<feature>,
#           which must already exist.
#
# Task-id normalisation: dots are replaced with hyphens (e.g. "1.1" → "1-1").
#
# Idempotency: if the target path already exists the script checks whether the
# registered worktree is on the expected branch (feat/<feature> by default, or
# <branch> when --base-ref is supplied). If yes it echoes the path and exits 0.
# If no it prints an error to stderr and exits 1.
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
  setup-worktree.sh parent <repo-name> <feature-slug> [--base-ref <branch>]
  setup-worktree.sh child  <repo-name> <feature-slug> <task-id>

Arguments:
  repo-name         Short name of the repository (e.g. "claude-plugins")
  feature-slug      Kebab-case feature identifier (e.g. "add-widget")
  task-id           Parallel-task identifier; dots are normalised to hyphens
                    (e.g. "1.1" → "1-1")
  --base-ref <b>    (parent only) Check out the existing branch <b> into the
                    worktree instead of creating a new feat/<feature> branch.
                    The branch will be fetched from origin if it does not
                    resolve locally.

Worktree locations:
  parent  ~/.claude-worktrees/<repo>-<feature>/
  child   ~/.claude-worktrees/<repo>-<feature>-<task-id>/

Branches:
  parent  feat/<feature>          (branched from HEAD; default)
  parent  <base-ref>              (checked out directly; with --base-ref)
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
  local base_ref="${3:-}"

  if [[ -z "$repo_name" || -z "$feature_slug" ]]; then
    _error "repo-name and feature-slug must not be empty"
    usage
    exit 1
  fi

  local worktrees_dir="${HOME}/.claude-worktrees"
  local parent_path="${worktrees_dir}/${repo_name}-${feature_slug}"

  # Branch the worktree will sit on:
  #   - default:       feat/<feature-slug>   (created from HEAD with -B)
  #   - --base-ref b:  b                     (checked out directly)
  local branch
  if [[ -n "$base_ref" ]]; then
    branch="$base_ref"
  else
    branch="feat/${feature_slug}"
  fi

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

  if [[ -n "$base_ref" ]]; then
    # Check out an existing branch into the worktree. Fetch once if the ref
    # does not resolve locally, then retry.
    if ! git rev-parse --verify "refs/heads/${base_ref}" >/dev/null 2>&1; then
      if ! git fetch origin "${base_ref}:${base_ref}" >/dev/null 2>&1; then
        _error "branch '${base_ref}' does not exist locally and could not be fetched from origin"
        exit 1
      fi
    fi

    git worktree add "$parent_path" "$base_ref"
  else
    # Create the parent worktree branching from HEAD.
    git worktree add -B "$branch" "$parent_path" HEAD
  fi

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
      local p_repo="" p_slug="" p_base_ref=""
      # Parse positional args + optional --base-ref.
      while [[ $# -gt 0 ]]; do
        case "$1" in
          --base-ref)
            if [[ $# -lt 2 ]]; then
              _error "'--base-ref' requires a branch argument"
              usage
              exit 1
            fi
            p_base_ref="$2"
            shift 2
            ;;
          --base-ref=*)
            p_base_ref="${1#--base-ref=}"
            shift
            ;;
          --)
            shift
            break
            ;;
          -*)
            _error "unknown flag in 'parent' mode: $1"
            usage
            exit 1
            ;;
          *)
            if [[ -z "$p_repo" ]]; then
              p_repo="$1"
            elif [[ -z "$p_slug" ]]; then
              p_slug="$1"
            else
              _error "'parent' mode takes at most 2 positional arguments: <repo-name> <feature-slug>"
              usage
              exit 1
            fi
            shift
            ;;
        esac
      done
      if [[ -z "$p_repo" || -z "$p_slug" ]]; then
        _error "'parent' mode requires <repo-name> and <feature-slug>"
        usage
        exit 1
      fi
      setup_parent "$p_repo" "$p_slug" "$p_base_ref"
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
