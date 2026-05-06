#!/usr/bin/env bash
# prepare-feature-branch.sh — ensure the current checkout is on the feature
# branch before dispatching implementor agents in --no-worktree mode.
#
# Usage:
#   prepare-feature-branch.sh <feature-slug> [--allow-existing-feature-branch]
#
# Behavior:
#   - Rejects an unrelated dirty checkout (only plan-artifact paths allowed:
#     docs/plans/<slug>/*, docs/prps/plans/<slug>*, docs/prps/specs/<slug>*).
#   - On feat/<slug>: idempotent no-op.
#   - On trunk (main/master) and feat/<slug> exists: switch to it.
#   - On trunk and feat/<slug> missing: create it.
#   - On another feature branch + --allow-existing-feature-branch: keep it.
#   - On another feature branch without the flag: exit 2 (caller asks user).
#
# Mirrors setup-worktree.sh stdout/stderr discipline:
#   - Branch name on stdout (one line).
#   - All git output and status messages on stderr.
#
# Exit codes:
#   0  branch is prepared (name on stdout)
#   1  hard failure (dirty unrelated tree, git error, missing slug, ...)
#   2  on a different feature branch and --allow-existing-feature-branch not set

set -euo pipefail

# ---------------------------------------------------------------------------
# Usage
# ---------------------------------------------------------------------------

usage() {
  cat >&2 <<'EOF'
Usage:
  prepare-feature-branch.sh <feature-slug> [--allow-existing-feature-branch]

Arguments:
  feature-slug                       Kebab-case feature identifier (e.g. "add-widget")
  --allow-existing-feature-branch    Reuse the current branch if it already starts
                                     with feat/ and differs from feat/<feature-slug>
EOF
}

_error() {
  echo "prepare-feature-branch.sh: error: $*" >&2
}

_info() {
  echo "prepare-feature-branch.sh: $*" >&2
}

# ---------------------------------------------------------------------------
# Argument parsing
# ---------------------------------------------------------------------------

FEATURE_SLUG=""
ALLOW_EXISTING_FEATURE_BRANCH=false

while [[ $# -gt 0 ]]; do
  case "$1" in
    --allow-existing-feature-branch)
      ALLOW_EXISTING_FEATURE_BRANCH=true
      shift
      ;;
    -h|--help)
      usage
      exit 0
      ;;
    --)
      shift
      break
      ;;
    -*)
      _error "unknown flag: $1"
      usage
      exit 1
      ;;
    *)
      if [[ -z "$FEATURE_SLUG" ]]; then
        FEATURE_SLUG="$1"
      else
        _error "unexpected positional argument: $1"
        usage
        exit 1
      fi
      shift
      ;;
  esac
done

if [[ -z "$FEATURE_SLUG" ]]; then
  _error "feature-slug is required"
  usage
  exit 1
fi

# ---------------------------------------------------------------------------
# Git context
# ---------------------------------------------------------------------------

if ! git rev-parse --git-dir >/dev/null 2>&1; then
  _error "not inside a git repository"
  exit 1
fi

CURRENT_BRANCH="$(git branch --show-current)"
if [[ -z "$CURRENT_BRANCH" ]]; then
  _error "detached HEAD is not supported; check out a branch first"
  exit 1
fi

FEATURE_BRANCH="feat/${FEATURE_SLUG}"

# ---------------------------------------------------------------------------
# Dirty-tree guard
# ---------------------------------------------------------------------------
#
# Allow plan-artifact paths; reject anything else.

is_plan_artifact() {
  local path="$1"
  case "$path" in
    docs/plans/"${FEATURE_SLUG}"/*) return 0 ;;
    docs/prps/plans/"${FEATURE_SLUG}"*) return 0 ;;
    docs/prps/specs/"${FEATURE_SLUG}"*) return 0 ;;
    docs/prps/prds/"${FEATURE_SLUG}"*) return 0 ;;
    *) return 1 ;;
  esac
}

UNRELATED_DIRTY=()
collect_dirty() {
  # Untracked files (file-level — avoids `?? dir/` collapsed entries from
  # `git status --porcelain` and `--untracked-files=all`'s memory cost).
  git ls-files --others --exclude-standard
  # Modified-but-unstaged tracked files.
  git diff --name-only
  # Staged tracked files (added/modified/renamed/deleted).
  git diff --name-only --cached
}

while IFS= read -r path; do
  [[ -z "$path" ]] && continue
  if ! is_plan_artifact "$path"; then
    UNRELATED_DIRTY+=("$path")
  fi
done < <(collect_dirty | sort -u)

if (( ${#UNRELATED_DIRTY[@]} > 0 )); then
  _error "working tree has unrelated changes; stash or commit them first:"
  printf '  %s\n' "${UNRELATED_DIRTY[@]}" >&2
  exit 1
fi

# ---------------------------------------------------------------------------
# Branch state machine
# ---------------------------------------------------------------------------

branch_exists() {
  git show-ref --verify --quiet "refs/heads/$1"
}

is_trunk_branch() {
  case "$1" in
    main|master|trunk|develop) return 0 ;;
    *) return 1 ;;
  esac
}

if [[ "$CURRENT_BRANCH" == "$FEATURE_BRANCH" ]]; then
  _info "already on ${FEATURE_BRANCH}"
  echo "$FEATURE_BRANCH"
  exit 0
fi

if is_trunk_branch "$CURRENT_BRANCH"; then
  if branch_exists "$FEATURE_BRANCH"; then
    _info "switching from ${CURRENT_BRANCH} to existing ${FEATURE_BRANCH}"
    git checkout "$FEATURE_BRANCH" >&2
  else
    _info "creating ${FEATURE_BRANCH} from ${CURRENT_BRANCH}"
    git checkout -b "$FEATURE_BRANCH" >&2
  fi
  echo "$FEATURE_BRANCH"
  exit 0
fi

# Some other branch — already a non-trunk branch, not feat/<slug>.
if [[ "$ALLOW_EXISTING_FEATURE_BRANCH" == true ]]; then
  _info "using current branch ${CURRENT_BRANCH} (--allow-existing-feature-branch)"
  echo "$CURRENT_BRANCH"
  exit 0
fi

_error "on branch '${CURRENT_BRANCH}', expected '${FEATURE_BRANCH}' or a trunk branch"
_error "pass --allow-existing-feature-branch to reuse the current branch, or check out a trunk branch first"
exit 2
