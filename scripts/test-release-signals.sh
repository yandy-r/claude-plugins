#!/usr/bin/env bash
#
# Behavioral tests for the release-model signal collector:
#   ycc/skills/release-model/scripts/collect-signals.sh
#
# Every test runs in throwaway git repos under a temp dir with an isolated git
# config, so the caller's repositories and global git settings are never used.
# A stub `gh` that always fails sits first on PATH so no test reaches the
# network; the gh tests swap in their own stubs or a PATH without gh.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SIGNALS="${REPO_ROOT}/ycc/skills/release-model/scripts/collect-signals.sh"
BASH_BIN="$(command -v bash)"

PASS=0
FAIL=0

RED=$'\033[0;31m'
GREEN=$'\033[0;32m'
NC=$'\033[0m'

# Git hooks (pre-push runs validate.sh) export GIT_DIR, GIT_WORK_TREE,
# GIT_INDEX_FILE and friends. Left set, they would point every sandbox git
# call at the caller's repository, so clear all repo-local git variables.
while IFS= read -r git_var; do
  unset "$git_var"
done < <(git rev-parse --local-env-vars)
unset git_var

SANDBOX_ROOT="$(mktemp -d)"
trap 'rm -rf "${SANDBOX_ROOT}"' EXIT

# Isolated git identity/config for every git call in this script.
export GIT_CONFIG_NOSYSTEM=1
export GIT_CONFIG_GLOBAL="${SANDBOX_ROOT}/gitconfig"
cat >"${GIT_CONFIG_GLOBAL}" <<'EOF'
[user]
	name = ycc test
	email = ycc-test@example.invalid
[init]
	defaultBranch = main
[commit]
	gpgsign = false
[tag]
	gpgsign = false
EOF

# A gh that is installed but never authenticated: keeps every test offline.
STUB_BIN="${SANDBOX_ROOT}/stub-bin"
mkdir -p "$STUB_BIN"
printf '#!/bin/sh\nexit 1\n' >"${STUB_BIN}/gh"
chmod +x "${STUB_BIN}/gh"
BASE_PATH="${STUB_BIN}:${PATH}"

ok() {
  PASS=$((PASS + 1))
  printf '%s[pass]%s %s\n' "${GREEN}" "${NC}" "$1"
}

ko() {
  FAIL=$((FAIL + 1))
  printf '%s[FAIL]%s %s\n' "${RED}" "${NC}" "$1"
  [[ -n "${2:-}" ]] && printf '       %s\n' "$2"
}

assert_eq() {
  local actual="$1" expected="$2" name="$3"
  if [[ "$actual" == "$expected" ]]; then
    ok "$name"
  else
    ko "$name" "expected: $(printf '%q' "$expected") got: $(printf '%q' "$actual")"
  fi
}

assert_contains() {
  local haystack="$1" needle="$2" name="$3"
  if [[ "$haystack" == *"$needle"* ]]; then
    ok "$name"
  else
    ko "$name" "missing: $needle"
  fi
}

assert_exit() {
  local actual="$1" expected="$2" name="$3"
  assert_eq "$actual" "$expected" "$name (exit $expected)"
}

# mkrepo — create a repo with one commit on main and a bare origin; echo path.
mkrepo() {
  local dir origin
  dir="$(mktemp -d "${SANDBOX_ROOT}/repo.XXXXXX")"
  origin="${dir}.origin.git"
  git init -q --bare "$origin"
  git -C "$dir" init -q
  # Refuse to continue if git resolved anything but the sandbox repo.
  if [[ "$(cd "$dir" && git rev-parse --absolute-git-dir)" != "${dir}/.git" ]]; then
    echo "test-release-signals: git did not resolve the sandbox repo; aborting" >&2
    exit 1
  fi
  echo "seed" >"${dir}/README.md"
  git -C "$dir" add README.md
  git -C "$dir" commit -q -m "chore: seed"
  git -C "$dir" remote add origin "$origin"
  git -C "$dir" push -q origin main 2>/dev/null
  git -C "$dir" remote set-head origin main >/dev/null 2>&1
  echo "$dir"
}

# get_key <output> <key> — value of key=value in output.
get_key() {
  printf '%s\n' "$1" | sed -n "s/^$2=//p"
}

# signals <repo> — run the collector with the offline gh stub first on PATH.
signals() {
  PATH="$BASE_PATH" "$BASH_BIN" "$SIGNALS" --repo "$1" 2>&1
}

# commit_n <repo> <count> <prefix> — add count empty commits.
commit_n() {
  local repo="$1" count="$2" prefix="$3" i
  for ((i = 1; i <= count; i++)); do
    git -C "$repo" commit -q --allow-empty -m "${prefix} ${i}"
  done
}

# tag_at <repo> <tag> <day> — annotated tag on a new commit, created on day N
# of January 2024 so the creation order is explicit.
tag_at() {
  local repo="$1" tag="$2" day="$3" date
  date="2024-01-$(printf '%02d' "$day")T12:00:00Z"
  GIT_COMMITTER_DATE="$date" GIT_AUTHOR_DATE="$date" \
    git -C "$repo" commit -q --allow-empty -m "chore(release): ${tag}"
  GIT_COMMITTER_DATE="$date" git -C "$repo" tag -a "$tag" -m "$tag"
}

# ---------------------------------------------------------------------------

test_no_tags() {
  local repo out
  repo="$(mkrepo)"
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" default_branch)" "main" "no tags: default branch from origin/HEAD"
  assert_eq "$(get_key "$out" tags_count)" "0" "no tags: tags_count=0"
  assert_eq "$(get_key "$out" latest_tag)" "" "no tags: latest_tag empty"
  assert_eq "$(get_key "$out" tag_pattern)" "none" "no tags: tag_pattern=none"
  assert_eq "$(get_key "$out" older_line_patched)" "0" "no tags: older_line_patched=0"
  assert_eq "$(get_key "$out" release_branches)" "" "no tags: no release branches"
  assert_eq "$(get_key "$out" publish_workflow)" "" "no tags: no publish workflow"
  assert_eq "$(get_key "$out" sync_merges_recent)" "0" "no tags: no sync merges"
  assert_eq "$(get_key "$out" linear_refs)" "0" "no tags: no issue keys"
  assert_eq "$(get_key "$out" suggested_model)" "trunk-only" "no tags: suggests trunk-only"
  assert_contains "$(get_key "$out" suggested_reason)" "No release tags yet" "no tags: reason"
}

test_key_order() {
  local repo keys expected
  repo="$(mkrepo)"
  keys="$(signals "$repo" | sed 's/=.*//' | paste -sd' ' -)"
  expected="default_branch long_lived_branches tags_count latest_tag tag_pattern older_line_patched release_branches gh_releases ci_trigger_branches publish_workflow version_files changelog sync_merges_recent linear_refs suggested_model suggested_reason"
  assert_eq "$keys" "$expected" "output: keys in documented order"
}

test_tags_in_order() {
  local repo out
  repo="$(mkrepo)"
  tag_at "$repo" v0.1.0 1
  tag_at "$repo" v0.1.1 2
  tag_at "$repo" v0.2.0 3
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" tags_count)" "3" "in-order tags: tags_count=3"
  assert_eq "$(get_key "$out" latest_tag)" "v0.2.0" "in-order tags: latest_tag"
  assert_eq "$(get_key "$out" tag_pattern)" "vX.Y.Z" "in-order tags: v prefix"
  assert_eq "$(get_key "$out" older_line_patched)" "0" "in-order tags: no older line patched"
  assert_eq "$(get_key "$out" suggested_model)" "trunk-only" "in-order tags: suggests trunk-only"
  assert_contains "$(get_key "$out" suggested_reason)" "no older line was patched" "in-order tags: reason"
}

test_older_line_patched() {
  local repo out
  repo="$(mkrepo)"
  tag_at "$repo" v0.1.0 1
  tag_at "$repo" v0.2.0 2
  tag_at "$repo" v0.1.1 3
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" older_line_patched)" "1" "older line: older_line_patched=1"
  assert_eq "$(get_key "$out" latest_tag)" "v0.2.0" "older line: latest_tag is the highest version"
  assert_eq "$(get_key "$out" suggested_model)" "release-branches" "older line: suggests release-branches"
  assert_contains "$(get_key "$out" suggested_reason)" "v0.1.1 was tagged after v0.2.0" "older line: reason names the tags"
}

test_unprefixed_tags() {
  local repo out
  repo="$(mkrepo)"
  tag_at "$repo" 1.0.0 1
  tag_at "$repo" 1.1.0 2
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" tag_pattern)" "X.Y.Z" "unprefixed tags: tag_pattern=X.Y.Z"
  assert_eq "$(get_key "$out" latest_tag)" "1.1.0" "unprefixed tags: latest_tag"
}

test_release_branches() {
  local repo out
  repo="$(mkrepo)"
  git -C "$repo" push -q origin main:refs/heads/release/0.5
  git -C "$repo" branch release/0.10
  git -C "$repo" branch release/0.5
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" release_branches)" "release/0.10,release/0.5" "release branches: origin and local, newest first, deduplicated"
  assert_eq "$(get_key "$out" suggested_model)" "release-branches" "release branches: suggests release-branches"
  assert_contains "$(get_key "$out" suggested_reason)" "release/0.10, release/0.5" "release branches: reason lists them"
}

test_long_lived_branches() {
  local repo out
  repo="$(mkrepo)"
  git -C "$repo" switch -q -c develop2
  commit_n "$repo" 21 "feat: long-lived"
  git -C "$repo" push -q origin develop2
  git -C "$repo" switch -q -c feat/short main
  commit_n "$repo" 3 "feat: short"
  git -C "$repo" push -q origin feat/short
  git -C "$repo" switch -q -c release/0.9 main
  commit_n "$repo" 25 "fix: backport"
  git -C "$repo" push -q origin release/0.9
  git -C "$repo" switch -q main
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" long_lived_branches)" "develop2" "long-lived: only the recent branch with >20 own commits (release/* excluded)"
}

test_sync_merges() {
  local repo out
  repo="$(mkrepo)"
  git -C "$repo" switch -q -c develop
  commit_n "$repo" 2 "feat: on develop"
  git -C "$repo" switch -q main
  git -C "$repo" merge -q --no-ff develop -m "Merge branch 'develop' into main"
  git -C "$repo" switch -q -c feature/sync-main-into-feature
  commit_n "$repo" 1 "feat: topic"
  git -C "$repo" switch -q main
  git -C "$repo" merge -q --no-ff feature/sync-main-into-feature -m "Merge pull request #3 from x/sync-main-into-feature"
  git -C "$repo" switch -q -c feature/normal
  commit_n "$repo" 1 "feat: normal"
  git -C "$repo" switch -q main
  git -C "$repo" merge -q --no-ff feature/normal -m "Merge branch 'feature/normal'"
  git -C "$repo" commit -q --allow-empty -m "chore: sync main into develop (not a merge)"
  git -C "$repo" push -q origin main
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" sync_merges_recent)" "2" "sync merges: counts sync-looking merge commits only"
}

test_linear_refs() {
  local repo out
  repo="$(mkrepo)"
  git -C "$repo" commit -q --allow-empty -m "fix: handle UTF-8 and CVE-2024-1 inputs"
  git -C "$repo" push -q origin main
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" linear_refs)" "0" "linear refs: UTF-8 and CVE ids are not issue keys"
  git -C "$repo" commit -q --allow-empty -m "feat: add export (ABC-123)"
  git -C "$repo" push -q origin main
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" linear_refs)" "1" "linear refs: commit subject with ABC-123"
  repo="$(mkrepo)"
  git -C "$repo" branch "feat/YAN-42-export"
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" linear_refs)" "1" "linear refs: branch name with YAN-42"
}

test_workflows() {
  local repo out wf
  repo="$(mkrepo)"
  wf="${repo}/.github/workflows"
  mkdir -p "$wf"
  cat >"${wf}/ci.yml" <<'EOF'
name: CI
on:
  push:
    branches: [main, 'release/**']
  pull_request:
    branches: [ignored-pr-branch]
jobs:
  release:
    runs-on: ubuntu-latest
EOF
  cat >"${wf}/lint.yaml" <<'EOF'
"on":
  pull_request:
  push:
    branches:
      - develop
      - "main"
    paths-ignore:
      - docs/**
jobs: {}
EOF
  cat >"${wf}/publish.yml" <<'EOF'
name: Publish
on:
  push:
    tags:
      - 'v*'
jobs:
  publish:
    runs-on: ubuntu-latest
EOF
  cat >"${wf}/zz-release-event.yml" <<'EOF'
on:
  release:
    types: [published]
EOF
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" ci_trigger_branches)" "main,release/**,develop" "workflows: push branches from inline and block lists, deduplicated"
  assert_eq "$(get_key "$out" publish_workflow)" ".github/workflows/publish.yml" "workflows: push tags sets publish_workflow"

  rm "${wf}/publish.yml"
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" publish_workflow)" ".github/workflows/zz-release-event.yml" "workflows: a release event also counts as publishing"

  rm "${wf}/zz-release-event.yml"
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" publish_workflow)" "" "workflows: a job named release is not a trigger"
}

test_files() {
  local repo out
  repo="$(mkrepo)"
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" version_files)" "" "files: none detected in a bare repo"
  assert_eq "$(get_key "$out" changelog)" "" "files: no changelog"
  mkdir -p "${repo}/cli" "${repo}/plug/.claude-plugin" "${repo}/.claude-plugin"
  printf '{\n  "name": "demo",\n  "version": "1.0.0"\n}\n' >"${repo}/package.json"
  printf '{\n  "name": "demo-cli"\n}\n' >"${repo}/cli/package.json"
  printf '[package]\nname = "demo"\nversion = "1.0.0"\n' >"${repo}/Cargo.toml"
  printf '{ "name": "plug", "version": "0.1.0" }\n' >"${repo}/plug/.claude-plugin/plugin.json"
  printf '{ "plugins": [{ "name": "plug", "version": "0.1.0" }] }\n' >"${repo}/.claude-plugin/marketplace.json"
  echo "# Changelog" >"${repo}/CHANGELOG.md"
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" version_files)" ".claude-plugin/marketplace.json,Cargo.toml,package.json,plug/.claude-plugin/plugin.json" "files: version-bearing manifests only"
  assert_eq "$(get_key "$out" changelog)" "CHANGELOG.md" "files: changelog path"
}

test_gh_absent() {
  local repo out toolbin tool path
  repo="$(mkrepo)"
  toolbin="${SANDBOX_ROOT}/no-gh-bin"
  mkdir -p "$toolbin"
  for tool in bash env git sed awk grep paste sort wc tr head find date; do
    path="$(command -v "$tool" || true)"
    [[ -n "$path" ]] && ln -sf "$path" "${toolbin}/${tool}"
  done
  if PATH="$toolbin" command -v gh >/dev/null 2>&1; then
    ko "gh absent: sandbox PATH hides gh"
    return
  fi
  out="$(PATH="$toolbin" "$BASH_BIN" "$SIGNALS" --repo "$repo" 2>&1)"
  assert_eq "$(get_key "$out" gh_releases)" "unknown" "gh absent: gh_releases=unknown"
  assert_eq "$(get_key "$out" suggested_model)" "trunk-only" "gh absent: collection still completes"
}

test_gh_stubs() {
  local repo out authed
  repo="$(mkrepo)"
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" gh_releases)" "unknown" "gh unauthenticated: gh_releases=unknown"
  authed="${SANDBOX_ROOT}/gh-authed"
  mkdir -p "$authed"
  cat >"${authed}/gh" <<'EOF'
#!/bin/sh
case "$1" in
  auth) exit 0 ;;
  release) echo 3 ;;
  *) exit 1 ;;
esac
EOF
  chmod +x "${authed}/gh"
  out="$(PATH="${authed}:${PATH}" "$BASH_BIN" "$SIGNALS" --repo "$repo" 2>&1)"
  assert_eq "$(get_key "$out" gh_releases)" "3" "gh authenticated: gh_releases is the release count"
}

test_errors() {
  local dir rc
  dir="$(mktemp -d "${SANDBOX_ROOT}/plain.XXXXXX")"
  PATH="$BASE_PATH" "$BASH_BIN" "$SIGNALS" --repo "$dir" >/dev/null 2>&1
  rc=$?
  assert_exit "$rc" 1 "errors: not a git repository"
  PATH="$BASE_PATH" "$BASH_BIN" "$SIGNALS" --bogus >/dev/null 2>&1
  rc=$?
  assert_exit "$rc" 1 "errors: unknown argument"
}

test_no_origin() {
  local repo out
  repo="$(mkrepo)"
  git -C "$repo" remote remove origin
  git -C "$repo" branch release/1.2
  out="$(signals "$repo")"
  assert_eq "$(get_key "$out" default_branch)" "main" "no origin: falls back to a local main"
  assert_eq "$(get_key "$out" release_branches)" "release/1.2" "no origin: local release branches"
}

# ---------------------------------------------------------------------------

test_no_tags
test_key_order
test_tags_in_order
test_older_line_patched
test_unprefixed_tags
test_release_branches
test_long_lived_branches
test_sync_merges
test_linear_refs
test_workflows
test_files
test_gh_absent
test_gh_stubs
test_errors
test_no_origin

echo
echo "release-signals tests: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
