#!/usr/bin/env bash
#
# Behavioral tests for the release-model branch check used by ycc:releaser:
#   ycc/skills/releaser/scripts/check-release-branch.sh
#
# Every test runs in throwaway git repos under a temp dir with an isolated git
# config, so the caller's repositories and global git settings are never used.
set -uo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(cd "${SCRIPT_DIR}/.." && pwd)"
CHECK="${REPO_ROOT}/ycc/skills/releaser/scripts/check-release-branch.sh"

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
    echo "test-release-releaser: git did not resolve the sandbox repo; aborting" >&2
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

# write_releasing <dir> <block-body> — write RELEASING.md with a state block.
write_releasing() {
  local dir="$1" body="$2"
  {
    echo "# Releasing"
    echo
    echo "<!-- ycc-release-state"
    printf '%s\n' "$body"
    echo "-->"
  } >"${dir}/RELEASING.md"
}

# get_key <output> <key> — value of key=value in output.
get_key() {
  printf '%s\n' "$1" | sed -n "s/^$2=//p"
}

# Shared fixture: release-branches with release/0.5 maintained and release/0.4 frozen.
RB_BLOCK="model: release-branches
trunk: main
maintenance: release/0.5
frozen: release/0.4"

# run_check <repo> <args...> — run the check; sets OUT (stdout), ERR (stderr), RC.
run_check() {
  local repo="$1" errfile
  shift
  errfile="$(mktemp "${SANDBOX_ROOT}/err.XXXXXX")"
  RC=0
  OUT="$(bash "$CHECK" --repo "$repo" "$@" 2>"$errfile")" || RC=$?
  ERR="$(cat "$errfile")"
}

# ---------------------------------------------------------------------------

test_no_releasing() {
  local repo
  repo="$(mkrepo)"
  run_check "$repo" 0.6.0
  assert_exit "$RC" 0 "no RELEASING.md: release proceeds"
  assert_eq "$(get_key "$OUT" present)" "0" "no RELEASING.md: present=0"
  assert_eq "$(get_key "$OUT" kind)" "minor" "no RELEASING.md: kind still reported"
  assert_contains "$ERR" "/ycc:release-model" "no RELEASING.md: suggests /ycc:release-model"
}

test_minor_on_trunk() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "$RB_BLOCK"
  run_check "$repo" 0.6.0
  assert_exit "$RC" 0 "release-branches: minor 0.6.0 on trunk"
  assert_eq "$(get_key "$OUT" kind)" "minor" "minor on trunk: kind=minor"
  assert_eq "$(get_key "$OUT" branch)" "main" "minor on trunk: branch=main"
  assert_eq "$(get_key "$OUT" creates_maintenance)" "release/0.6" "minor on trunk: creates_maintenance"
  assert_eq "$(get_key "$OUT" backport_label)" "backport:0.6" "minor on trunk: backport label resolved"
  assert_eq "$(get_key "$OUT" forward_port)" "0" "minor on trunk: no forward port"
}

test_major_on_trunk() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "$RB_BLOCK"
  run_check "$repo" v1.0.0
  assert_exit "$RC" 0 "release-branches: major v1.0.0 on trunk"
  assert_eq "$(get_key "$OUT" kind)" "major" "major on trunk: kind=major"
  assert_eq "$(get_key "$OUT" version)" "1.0.0" "major on trunk: leading v stripped"
  assert_eq "$(get_key "$OUT" creates_maintenance)" "release/1.0" "major on trunk: creates release/1.0"
}

test_minor_on_release_branch() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "$RB_BLOCK"
  git -C "$repo" switch -q -c release/0.5
  run_check "$repo" 0.6.0
  assert_exit "$RC" 1 "release-branches: minor on release/0.5 refused"
  assert_contains "$ERR" "git switch main" "minor on release/0.5: prints git switch main"
  assert_eq "$OUT" "" "minor on release/0.5: nothing on stdout"
}

test_minor_already_shipped() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "$RB_BLOCK"
  run_check "$repo" 0.5.0
  assert_exit "$RC" 1 "release-branches: 0.5.0 when release/0.5 exists refused"
  assert_contains "$ERR" "already recorded" "0.5.0 again: explains the branch exists"
}

test_patch_on_maintenance() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "$RB_BLOCK"
  git -C "$repo" switch -q -c release/0.5
  run_check "$repo" 0.5.3
  assert_exit "$RC" 0 "release-branches: patch 0.5.3 on release/0.5"
  assert_eq "$(get_key "$OUT" kind)" "patch" "patch on release/0.5: kind=patch"
  assert_eq "$(get_key "$OUT" branch)" "release/0.5" "patch on release/0.5: branch"
  assert_eq "$(get_key "$OUT" creates_maintenance)" "" "patch on release/0.5: creates nothing"
  assert_eq "$(get_key "$OUT" forward_port)" "1" "patch on release/0.5: forward_port=1"
}

test_patch_wrong_line() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "model: release-branches
trunk: main
maintenance: release/0.6, release/0.5"
  git -C "$repo" switch -q -c release/0.5
  run_check "$repo" 0.6.1
  assert_exit "$RC" 1 "release-branches: patch 0.6.1 on release/0.5 refused"
  assert_contains "$ERR" "git switch release/0.6" "patch 0.6.1 on release/0.5: prints git switch release/0.6"
}

test_patch_not_maintained() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "$RB_BLOCK"
  git -C "$repo" switch -q -c release/0.5
  run_check "$repo" 0.6.1
  assert_exit "$RC" 1 "release-branches: patch 0.6.1 with no release/0.6 refused"
  assert_contains "$ERR" "not a maintenance branch" "patch without maintenance branch: explains"
  assert_contains "$ERR" "git push origin v0.6.0^{commit}:refs/heads/release/0.6" \
    "patch without maintenance branch: prints the command that creates it"
}

test_patch_on_trunk_refused() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "$RB_BLOCK"
  run_check "$repo" 0.5.3
  assert_exit "$RC" 1 "release-branches: patch 0.5.3 on trunk refused"
  assert_contains "$ERR" "git switch release/0.5" "patch on trunk: prints git switch release/0.5"
}

test_patch_frozen() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "$RB_BLOCK"
  git -C "$repo" switch -q -c release/0.4
  run_check "$repo" 0.4.2
  assert_exit "$RC" 1 "release-branches: patch on frozen release/0.4 refused"
  assert_contains "$ERR" "frozen" "frozen branch: explains why"
}

test_trunk_only_patch_on_trunk() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "model: trunk-only
trunk: main"
  run_check "$repo" 0.5.3
  assert_exit "$RC" 0 "trunk-only: patch on trunk"
  assert_eq "$(get_key "$OUT" model)" "trunk-only" "trunk-only patch: model"
  assert_eq "$(get_key "$OUT" kind)" "patch" "trunk-only patch: kind=patch"
  assert_eq "$(get_key "$OUT" creates_maintenance)" "" "trunk-only patch: creates nothing"
  assert_eq "$(get_key "$OUT" forward_port)" "0" "trunk-only patch: no forward port"
}

test_trunk_only_other_branch() {
  local repo version
  repo="$(mkrepo)"
  write_releasing "$repo" "model: trunk-only
trunk: main"
  git -C "$repo" switch -q -c feat/thing
  for version in 0.6.0 0.5.3 1.0.0; do
    run_check "$repo" "$version"
    assert_exit "$RC" 1 "trunk-only: $version on feat/thing refused"
    assert_contains "$ERR" "git switch main" "trunk-only $version off trunk: prints git switch main"
  done
  # --branch overrides the checked-out branch.
  run_check "$repo" 0.6.0 --branch main
  assert_exit "$RC" 0 "trunk-only: --branch main overrides HEAD"
}

test_prerelease_on_trunk() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "$RB_BLOCK"
  run_check "$repo" 0.7.0-beta.1
  assert_exit "$RC" 0 "release-branches: pre-release 0.7.0-beta.1 on trunk"
  assert_eq "$(get_key "$OUT" kind)" "minor" "pre-release: kind=minor"
  assert_eq "$(get_key "$OUT" creates_maintenance)" "" "pre-release: release/0.7 waits for 0.7.0"
  git -C "$repo" switch -q -c release/0.6
  run_check "$repo" 0.7.0-beta.1
  assert_exit "$RC" 1 "release-branches: pre-release off trunk refused"
}

test_custom_trunk_and_label() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "model: release-branches
trunk: master
maintenance: release/0.5
backport_label: needs-backport/{X.Y}"
  git -C "$repo" switch -q -c master
  run_check "$repo" 0.6.0
  assert_exit "$RC" 0 "custom trunk: minor on master"
  assert_eq "$(get_key "$OUT" trunk)" "master" "custom trunk: trunk=master"
  assert_eq "$(get_key "$OUT" backport_label)" "needs-backport/0.6" "custom label template resolved"
}

test_malformed() {
  local repo
  repo="$(mkrepo)"
  write_releasing "$repo" "model: release-branches
trunk: main
flavour: vanilla"
  run_check "$repo" 0.6.0
  assert_exit "$RC" 2 "malformed state block"
  assert_contains "$ERR" "unknown key 'flavour'" "malformed: shows the parse error"
  assert_eq "$OUT" "" "malformed: nothing on stdout"
}

test_bad_input() {
  local repo
  repo="$(mkrepo)"
  run_check "$repo" 1.2
  assert_exit "$RC" 1 "invalid version rejected"
  run_check "$repo"
  assert_exit "$RC" 1 "missing version rejected"
}

# ---------------------------------------------------------------------------

test_no_releasing
test_minor_on_trunk
test_major_on_trunk
test_minor_on_release_branch
test_minor_already_shipped
test_patch_on_maintenance
test_patch_wrong_line
test_patch_not_maintained
test_patch_on_trunk_refused
test_patch_frozen
test_trunk_only_patch_on_trunk
test_trunk_only_other_branch
test_prerelease_on_trunk
test_custom_trunk_and_label
test_malformed
test_bad_input

echo
echo "release-releaser tests: ${PASS} passed, ${FAIL} failed"
[[ "$FAIL" -eq 0 ]]
