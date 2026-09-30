#!/usr/bin/env bash
#
# Behavioral tests for the release-model branch and PR helpers:
#   ycc/skills/_shared/scripts/prepare-feature-branch.sh
#
# Every test runs in throwaway git repos under a temp dir with an isolated git
# config, so the caller's repositories and global git settings are never used.
# The harness below is copied from scripts/test-release-model.sh.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
SHARED="${REPO_ROOT}/ycc/skills/_shared/scripts"
PREP="${SHARED}/prepare-feature-branch.sh"

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
    echo "test-release-branch-prep: git did not resolve the sandbox repo; aborting" >&2
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

# write_releasing <dir> <block-body> [table-and-prose] — write RELEASING.md.
write_releasing() {
  local dir="$1" body="$2" rest="${3:-}"
  {
    echo "# Releasing"
    echo
    echo "<!-- ycc-release-state"
    printf '%s\n' "$body"
    echo "-->"
    [[ -n "$rest" ]] && printf '\n%s\n' "$rest"
  } >"${dir}/RELEASING.md"
}

# get_key <output> <key> — value of key=value in output.
get_key() {
  printf '%s\n' "$1" | sed -n "s/^$2=//p"
}


# ---------------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------------

# commit_file <repo> <file> <content> <message> — write, add and commit.
commit_file() {
  local repo="$1" file="$2" content="$3" msg="$4"
  mkdir -p "$(dirname "${repo}/${file}")"
  printf '%s\n' "$content" >"${repo}/${file}"
  git -C "$repo" add "$file"
  git -C "$repo" commit -q -m "$msg"
}

# sha <repo> <ref> — full commit id of ref.
sha() {
  git -C "$1" rev-parse "$2"
}

# current_branch <repo>
current_branch() {
  git -C "$1" branch --show-current
}

# run_prep <repo> [args...] — run prepare-feature-branch.sh inside repo;
# stdout to PREP_OUT, stderr to PREP_ERR, exit code to PREP_RC.
run_prep() {
  local repo="$1" errf
  shift
  errf="$(mktemp "${SANDBOX_ROOT}/err.XXXXXX")"
  PREP_RC=0
  PREP_OUT="$(cd "$repo" && bash "$PREP" "$@" 2>"$errf")" || PREP_RC=$?
  PREP_ERR="$(cat "$errf")"
}

# release_repo <block-body> — mkrepo with RELEASING.md committed and pushed.
release_repo() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "$1"
  git -C "$repo" add RELEASING.md
  git -C "$repo" commit -q -m "docs: add RELEASING.md"
  git -C "$repo" push -q origin main
  echo "$repo"
}

# make_local_trunk_behind <repo> <trunk> — push one commit to origin/<trunk>,
# then rewind both the local branch and origin/<trunk> so only a fetch sees it.
make_local_trunk_behind() {
  local repo="$1" trunk="$2" old
  old="$(sha "$repo" HEAD)"
  commit_file "$repo" "ahead-${trunk}.txt" "ahead" "feat: upstream work on ${trunk}"
  git -C "$repo" push -q origin "$trunk"
  git -C "$repo" reset -q --hard "$old"
  git -C "$repo" update-ref "refs/remotes/origin/${trunk}" "$old"
}

REL_BLOCK="model: release-branches
trunk: main
maintenance: release/0.5"

# ---------------------------------------------------------------------------
# prepare-feature-branch.sh
# ---------------------------------------------------------------------------

test_prep_no_state_unchanged() {
  local repo head
  repo="$(mkrepo)"
  make_local_trunk_behind "$repo" main
  head="$(sha "$repo" HEAD)"
  run_prep "$repo" demo
  assert_exit "$PREP_RC" 0 "prep: no RELEASING.md creates the branch"
  assert_eq "$PREP_OUT" "feat/demo" "prep: no RELEASING.md prints the branch"
  assert_eq "$(sha "$repo" feat/demo)" "$head" "prep: no RELEASING.md branches from HEAD, not origin"
  assert_eq "$PREP_ERR" "prepare-feature-branch.sh: creating feat/demo from main
Switched to a new branch 'feat/demo'" "prep: no RELEASING.md stderr unchanged"

  repo="$(mkrepo)"
  git -C "$repo" checkout -q -b release/0.5
  run_prep "$repo" demo
  assert_exit "$PREP_RC" 2 "prep: no RELEASING.md treats release/* as a feature branch"
  assert_contains "$PREP_ERR" "--allow-existing-feature-branch" "prep: no RELEASING.md keeps the old exit-2 message"

  repo="$(mkrepo)"
  git -C "$repo" checkout -q -b develop2
  run_prep "$repo" demo
  assert_exit "$PREP_RC" 2 "prep: no RELEASING.md does not treat develop2 as a trunk"
}

test_prep_state_trunk_nonstandard() {
  local repo
  repo="$(mkrepo)"
  git -C "$repo" checkout -q -b develop2
  write_releasing "$repo" "model: trunk-only
trunk: develop2"
  git -C "$repo" add RELEASING.md
  git -C "$repo" commit -q -m "docs: add RELEASING.md"
  git -C "$repo" push -q origin develop2
  run_prep "$repo" demo
  assert_exit "$PREP_RC" 0 "prep: state trunk develop2 is a trunk"
  assert_eq "$(current_branch "$repo")" "feat/demo" "prep: switched to feat/demo from develop2"
  assert_eq "$(sha "$repo" feat/demo)" "$(sha "$repo" origin/develop2)" "prep: feat/demo starts at origin/develop2"
}

test_prep_branches_from_origin_trunk() {
  local repo upstream
  repo="$(release_repo "$REL_BLOCK")"
  make_local_trunk_behind "$repo" main
  upstream="$(git -C "${repo}.origin.git" rev-parse main)"
  run_prep "$repo" demo
  assert_exit "$PREP_RC" 0 "prep: state present creates the branch"
  assert_eq "$PREP_OUT" "feat/demo" "prep: state present prints the branch"
  assert_eq "$(sha "$repo" feat/demo)" "$upstream" "prep: branch starts at freshly fetched origin/main"
  assert_eq "$(git -C "$repo" config --get branch.feat/demo.merge || true)" "" "prep: branch has no upstream to origin/main"
  assert_contains "$PREP_ERR" "from origin/main" "prep: reports origin/<trunk> as the start point"
}

test_prep_from_other_trunk_uses_state_trunk() {
  local repo
  repo="$(mkrepo)"
  git -C "$repo" checkout -q -b develop2
  commit_file "$repo" dev.txt "dev" "feat: develop2 work"
  git -C "$repo" push -q origin develop2
  git -C "$repo" checkout -q main
  write_releasing "$repo" "model: trunk-only
trunk: develop2"
  git -C "$repo" add RELEASING.md
  git -C "$repo" commit -q -m "docs: add RELEASING.md"
  run_prep "$repo" demo
  assert_exit "$PREP_RC" 0 "prep: on main with state trunk develop2"
  assert_eq "$(sha "$repo" feat/demo)" "$(sha "$repo" origin/develop2)" "prep: on main, branch starts at origin/<state trunk>"
}

test_prep_plan_files_carried() {
  local repo
  repo="$(release_repo "$REL_BLOCK")"
  make_local_trunk_behind "$repo" main
  mkdir -p "${repo}/docs/plans/demo"
  echo "plan" >"${repo}/docs/plans/demo/plan.md"
  run_prep "$repo" demo
  assert_exit "$PREP_RC" 0 "prep: plan-only dirty tree is allowed"
  assert_eq "$(sha "$repo" feat/demo)" "$(sha "$repo" origin/main)" "prep: plan-only dirty tree still branches from origin/main"
  assert_eq "$(cat "${repo}/docs/plans/demo/plan.md")" "plan" "prep: untracked plan file carried over"
}

test_prep_plan_conflict_falls_back() {
  local repo head
  repo="$(release_repo "$REL_BLOCK")"
  head="$(sha "$repo" HEAD)"
  commit_file "$repo" docs/plans/demo/plan.md "upstream plan" "docs: upstream plan"
  git -C "$repo" push -q origin main
  git -C "$repo" reset -q --hard "$head"
  mkdir -p "${repo}/docs/plans/demo"
  echo "local plan" >"${repo}/docs/plans/demo/plan.md"
  run_prep "$repo" demo
  assert_exit "$PREP_RC" 0 "prep: conflicting plan file falls back"
  assert_eq "$(sha "$repo" feat/demo)" "$head" "prep: conflicting plan file branches from HEAD"
  assert_eq "$(current_branch "$repo")" "feat/demo" "prep: conflicting plan file ends on feat/demo"
  assert_contains "$PREP_ERR" "warning: could not create feat/demo from origin/main" "prep: conflicting plan file warns"
  assert_eq "$(cat "${repo}/docs/plans/demo/plan.md")" "local plan" "prep: local plan file kept"
}

test_prep_release_branch() {
  local repo release_sha
  repo="$(release_repo "$REL_BLOCK")"
  git -C "$repo" checkout -q -b release/0.5
  commit_file "$repo" patch.txt "patch" "fix: release-only"
  git -C "$repo" push -q origin release/0.5
  release_sha="$(sha "$repo" HEAD)"

  run_prep "$repo" demo
  assert_exit "$PREP_RC" 2 "prep: on release/0.5 without the flag"
  assert_contains "$PREP_ERR" "release-only fix" "prep: release/0.5 asks about a release-only fix"
  assert_contains "$PREP_ERR" "--allow-release-branch" "prep: release/0.5 names the flag"
  assert_eq "$(current_branch "$repo")" "release/0.5" "prep: release/0.5 refusal leaves the branch alone"

  run_prep "$repo" demo --allow-existing-feature-branch
  assert_exit "$PREP_RC" 2 "prep: --allow-existing-feature-branch does not bypass the release check"

  run_prep "$repo" demo --allow-release-branch
  assert_exit "$PREP_RC" 0 "prep: --allow-release-branch proceeds"
  assert_eq "$PREP_OUT" "feat/demo" "prep: --allow-release-branch prints the branch"
  assert_eq "$(sha "$repo" feat/demo)" "$release_sha" "prep: --allow-release-branch branches from the release branch"

  git -C "$repo" checkout -q release/0.5
  run_prep "$repo" demo --allow-release-branch
  assert_exit "$PREP_RC" 0 "prep: --allow-release-branch reuses an existing feat/demo"
  assert_eq "$(current_branch "$repo")" "feat/demo" "prep: --allow-release-branch switched to feat/demo"
}

test_prep_fetch_failure() {
  local repo head
  repo="$(release_repo "$REL_BLOCK")"
  head="$(sha "$repo" HEAD)"
  git -C "$repo" remote remove origin
  run_prep "$repo" demo
  assert_exit "$PREP_RC" 0 "prep: fetch failure still creates the branch"
  assert_eq "$(sha "$repo" feat/demo)" "$head" "prep: fetch failure branches from HEAD"
  assert_contains "$PREP_ERR" "warning: could not fetch main from origin" "prep: fetch failure warns"
}

test_prep_malformed_state() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "model: trunk-only
trunk: main
flavour: vanilla"
  git -C "$repo" add RELEASING.md
  git -C "$repo" commit -q -m "docs: add RELEASING.md"
  run_prep "$repo" demo
  assert_exit "$PREP_RC" 1 "prep: malformed RELEASING.md"
  assert_contains "$PREP_ERR" "unknown key 'flavour'" "prep: malformed RELEASING.md shows the parse error"
  assert_eq "$(current_branch "$repo")" "main" "prep: malformed RELEASING.md leaves the branch alone"
}

# ---------------------------------------------------------------------------

test_prep_no_state_unchanged
test_prep_state_trunk_nonstandard
test_prep_branches_from_origin_trunk
test_prep_from_other_trunk_uses_state_trunk
test_prep_plan_files_carried
test_prep_plan_conflict_falls_back
test_prep_release_branch
test_prep_fetch_failure
test_prep_malformed_state

echo
echo "release branch-prep tests: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
