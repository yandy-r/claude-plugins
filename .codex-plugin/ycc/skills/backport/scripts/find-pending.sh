#!/usr/bin/env bash
# find-pending.sh — list merged PRs that carry a backport label but have no
# backport PR yet.
#
# Usage:
#   find-pending.sh [--repo DIR] [--label-prefix PREFIX]
#
# Reads the release state from DIR/RELEASING.md (via release-state.sh), lists
# every label that starts with the backport-label prefix (derived from the
# state's backport_label by cutting at "{X.Y}", e.g. "backport:"), collects the
# merged PRs carrying each label, and drops every (PR, target) pair for which a
# PR into that target branch already exists (any state) whose body contains
# "Backport of #<N>".
#
# Output (stdout), one line per pending pair, sorted by PR number:
#   <pr_number>\t<release/X.Y>\t<merge_commit_sha>\t<title>
#
# Only active maintenance branches (the state's `maintenance` list) are
# targets. Labels that name any other branch are reported on stderr as
# "skip: ..." and never printed on stdout.
#
# Requires: gh (authenticated), jq, git. GitHub only.
#
# Exit codes:
#   0  success (possibly no pending pairs)
#   1  usage error, missing/unauthenticated gh, missing jq, no RELEASING.md,
#      or a gh query failed
#   2  RELEASING.md exists but its state block is malformed
#
# Rules: ~/.codex/plugins/ycc/shared/references/branching-model.md#backporting

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
STATE_SCRIPT="${SCRIPT_DIR}/../../../shared/scripts/release-state.sh"
PR_LIMIT=1000

_error() {
  echo "find-pending: $*" >&2
}

usage() {
  sed -n '2,31p' "${BASH_SOURCE[0]}" | sed 's/^# \{0,1\}//' >&2
}

REPO_DIR="."
PREFIX_OVERRIDE=""

while [[ $# -gt 0 ]]; do
  case "$1" in
    --repo)
      [[ $# -lt 2 ]] && { _error "--repo requires a directory"; exit 1; }
      REPO_DIR="$2"
      shift 2
      ;;
    --label-prefix)
      [[ $# -lt 2 || -z "${2:-}" ]] && { _error "--label-prefix requires a value"; exit 1; }
      PREFIX_OVERRIDE="$2"
      shift 2
      ;;
    -h | --help)
      usage
      exit 0
      ;;
    *)
      _error "unknown argument: $1"
      usage
      exit 1
      ;;
  esac
done

if ! command -v gh >/dev/null 2>&1; then
  _error "the GitHub CLI 'gh' is not installed; install it from https://cli.github.com and run 'gh auth login'"
  exit 1
fi
if ! command -v jq >/dev/null 2>&1; then
  _error "'jq' is required but not installed"
  exit 1
fi
if [[ ! -d "$REPO_DIR" ]]; then
  _error "no such directory: $REPO_DIR"
  exit 1
fi

# ---------------------------------------------------------------------------
# Release state
# ---------------------------------------------------------------------------

rc=0
STATE_OUT="$(bash "$STATE_SCRIPT" --repo "$REPO_DIR" get)" || rc=$?
if [[ "$rc" -eq 2 ]]; then
  _error "RELEASING.md has a malformed state block (see above); run $release-model --audit"
  exit 2
elif [[ "$rc" -ne 0 ]]; then
  _error "could not read the release state"
  exit 1
fi

state_key() {
  printf '%s\n' "$STATE_OUT" | sed -n "s/^$1=//p"
}

if [[ "$(state_key present)" != "1" ]]; then
  _error "no RELEASING.md in ${REPO_DIR}; backports need a release-branches model (run $release-model)"
  exit 1
fi

MODEL="$(state_key model)"
MAINTENANCE="$(state_key maintenance)"
LABEL_TEMPLATE="$(state_key backport_label)"

if [[ "$MODEL" != "release-branches" || -z "$MAINTENANCE" ]]; then
  echo "find-pending: model '${MODEL}' has no active maintenance branches; nothing to backport" >&2
  exit 0
fi

LABEL_PREFIX="${PREFIX_OVERRIDE:-${LABEL_TEMPLATE%%\{X.Y\}*}}"
LABEL_SUFFIX="${LABEL_TEMPLATE#*\{X.Y\}}"
if [[ -z "$LABEL_PREFIX" ]]; then
  _error "backport_label '${LABEL_TEMPLATE}' has no prefix before {X.Y}; pass --label-prefix"
  exit 1
fi

# is_active <branch> — true when branch is in the maintenance list.
is_active() {
  [[ ",${MAINTENANCE}," == *",$1,"* ]]
}

# ---------------------------------------------------------------------------
# GitHub queries (run from the repo so gh resolves its remote)
# ---------------------------------------------------------------------------

cd "$REPO_DIR"

if ! gh auth status >/dev/null 2>&1; then
  _error "gh is not authenticated; run 'gh auth login'"
  exit 1
fi

gh_json() {
  local out
  if ! out="$(gh "$@" 2>&1)"; then
    _error "gh $* failed: ${out}"
    exit 1
  fi
  printf '%s\n' "$out"
}

LABELS_JSON="$(gh_json label list --search "$LABEL_PREFIX" --limit "$PR_LIMIT" --json name)"
mapfile -t LABELS < <(
  jq -r --arg p "$LABEL_PREFIX" '.[].name | select(startswith($p))' <<<"$LABELS_JSON" | sort -u
)

# BACKPORT_BODIES[target] holds the bodies of every PR (any state) into that
# active maintenance branch. Fetched once per branch, in the main shell.
declare -A BACKPORT_BODIES=()
IFS=',' read -r -a ACTIVE_BRANCHES <<<"$MAINTENANCE"
if [[ "${#LABELS[@]}" -gt 0 ]]; then
  for target in "${ACTIVE_BRANCHES[@]}"; do
    bodies_json="$(gh_json pr list --state all --base "$target" --limit "$PR_LIMIT" --json number,body)"
    BACKPORT_BODIES[$target]="$(jq -r '.[].body // ""' <<<"$bodies_json")"
  done
fi

# already_backported <pr> <target> — true when a PR into target references
# "Backport of #<pr>" (not followed by another digit).
already_backported() {
  grep -Eq "Backport of #$1([^0-9]|\$)" <<<"${BACKPORT_BODIES[$2]:-}"
}

PENDING=""
for label in "${LABELS[@]}"; do
  version="${label#"$LABEL_PREFIX"}"
  version="${version%"$LABEL_SUFFIX"}"
  if [[ ! "$version" =~ ^[0-9]+\.[0-9]+$ ]]; then
    echo "find-pending: skip: label '${label}' does not name a version X.Y" >&2
    continue
  fi
  target="release/${version}"
  prs_json="$(gh_json pr list --state merged --label "$label" --limit "$PR_LIMIT" --json number,title,mergeCommit)"
  while IFS=$'\t' read -r number sha title; do
    [[ -z "$number" ]] && continue
    if ! is_active "$target"; then
      echo "find-pending: skip: #${number} (${label}): ${target} is not an active maintenance branch" >&2
      continue
    fi
    if [[ -z "$sha" ]]; then
      echo "find-pending: skip: #${number} (${label}): no merge commit reported by GitHub" >&2
      continue
    fi
    if already_backported "$number" "$target"; then
      continue
    fi
    PENDING+="${number}"$'\t'"${target}"$'\t'"${sha}"$'\t'"${title}"$'\n'
  done < <(jq -r '.[] | [(.number | tostring), (.mergeCommit.oid // ""), (.title | gsub("[\t\n]"; " "))] | @tsv' <<<"$prs_json")
done

if [[ -n "$PENDING" ]]; then
  printf '%s' "$PENDING" | sort -t $'\t' -k1,1n -k2,2
fi
