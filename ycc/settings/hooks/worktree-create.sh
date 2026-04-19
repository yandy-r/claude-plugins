#!/usr/bin/env bash
# worktree-create.sh — WorktreeCreate hook for Claude Code
#
# CONTRACT (verified against https://docs.claude.com/en/docs/claude-code/hooks):
#   stdin  : JSON object with at minimum:
#              { "worktree_path": "/repo/.claude/worktrees/...",
#                "cwd":           "/repo",
#                "base_ref":      "main",
#                "worktree_name": "...",
#                "session_id":    "...",
#                "hook_event_name": "WorktreeCreate" }
#   stdout : A single line containing the replacement worktree path (plain text, NOT JSON).
#   exit 0 : Worktree creation proceeds using the path on stdout.
#   exit ≠0: Worktree creation FAILS (unlike other hooks where only exit 2 blocks).
#
# PURPOSE:
#   The Claude Code harness defaults to creating worktrees at
#   <repo>/.claude/worktrees/<name>, polluting the repo working tree.
#   This hook intercepts the intended path and redirects the worktree to
#   ~/.claude-worktrees/<repo-name>-<branch>/ instead.
#
# INSTALL:
#   ~/.claude/hooks/ must resolve to (or contain) this file.
#   The simplest approach is a symlink:
#     ln -s "$(pwd)/ycc/settings/hooks" ~/.claude/hooks
#   See CONTRIBUTING.md → Developer Setup for details.

set -euo pipefail

# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# Read the full stdin payload once.
INPUT="$(cat)"

# Try to extract a field value from the JSON input.
# Uses jq when available; falls back to a simple grep-based extraction.
json_get() {
  local field="$1"
  if command -v jq &>/dev/null; then
    printf '%s' "$INPUT" | jq -r --arg f "$field" '.[$f] // empty'
  else
    # Fallback: extract "field": "value" (handles most well-formed JSON).
    printf '%s' "$INPUT" \
      | grep -o "\"${field}\"[[:space:]]*:[[:space:]]*\"[^\"]*\"" \
      | head -1 \
      | sed 's/.*: *"\(.*\)"/\1/'
  fi
}

# ---------------------------------------------------------------------------
# Parse input
# ---------------------------------------------------------------------------

INTENDED_PATH="$(json_get worktree_path)"
CWD="$(json_get cwd)"
BASE_REF="$(json_get base_ref)"

# If we couldn't parse a path, fall back to the harness default (fail open).
if [[ -z "$INTENDED_PATH" ]]; then
  # Nothing sensible to redirect — let the harness proceed with its default.
  # We must still print a path; emit an empty string to signal "use default".
  # However the docs say missing path = failure, so we try cwd-based fallback.
  if [[ -n "$CWD" ]]; then
    printf '%s/.claude/worktrees/fallback\n' "$CWD"
  else
    # Absolute last resort: exit 0 with no output (will likely fail creation,
    # but that is safer than blocking with exit 1 when input is malformed).
    printf ''
  fi
  exit 0
fi

# ---------------------------------------------------------------------------
# Compute replacement path
# ---------------------------------------------------------------------------

# Repo name: basename of the directory that contains .claude/worktrees,
# or basename of cwd, whichever we can derive.
#
# The harness path is typically  <repo>/.claude/worktrees/<something>
# so strip the trailing /.claude/worktrees/<something> suffix to get <repo>.
REPO_ROOT="${INTENDED_PATH%/.claude/worktrees/*}"
if [[ "$REPO_ROOT" == "$INTENDED_PATH" ]]; then
  # Pattern didn't match — use cwd as repo root.
  REPO_ROOT="${CWD:-$PWD}"
fi
REPO_NAME="$(basename "$REPO_ROOT")"

# Branch: prefer the incoming base_ref if set; otherwise ask git.
BRANCH="${BASE_REF:-}"
if [[ -z "$BRANCH" ]] && command -v git &>/dev/null; then
  BRANCH="$(git -C "$REPO_ROOT" rev-parse --abbrev-ref HEAD 2>/dev/null || true)"
fi
# Sanitise: replace characters unsafe in directory names with '-'.
BRANCH="${BRANCH//\//-}"
BRANCH="${BRANCH//[^a-zA-Z0-9._-]/-}"
BRANCH="${BRANCH:-unknown}"

REPLACEMENT="$HOME/.claude-worktrees/${REPO_NAME}-${BRANCH}"

# ---------------------------------------------------------------------------
# Ensure parent directory exists (not the worktree itself — git does that).
# ---------------------------------------------------------------------------
mkdir -p "$HOME/.claude-worktrees"

# ---------------------------------------------------------------------------
# Emit replacement path
# ---------------------------------------------------------------------------
printf '%s\n' "$REPLACEMENT"
exit 0
