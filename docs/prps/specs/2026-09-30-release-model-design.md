# Release model for the ycc bundle — design

- **Date:** 2026-09-30
- **Status:** approved in conversation, awaiting written-spec review
- **Origin:** the branching and release model adopted in `yandy-r/9router` (`RELEASING.md`, PRs #368, #371, #374)

## 1. Intent

Projects built with ycc have no written branching or release model. Agents pick base
branches ad hoc, releases get assembled by cherry-picking commits after the fact, and
long-lived branches need repeated "sync main into X" merges that waste time and CI
minutes. 9router fixed this with a repo-root `RELEASING.md` that every agent reads.

This work makes that approach a first-class part of ycc:

- A project's `RELEASING.md` becomes the single source of truth for its trunk,
  maintenance branches, and release steps.
- `init`, `blueprint` and `releaser` detect a missing `RELEASING.md` and offer a
  workflow that generates one tailored to the project.
- The skills that choose branches, open PRs, cut releases, and clean up branches follow
  the file automatically, so the user never restates the model in prompts.

**Success looks like:** in a repo with `RELEASING.md`, every ycc skill picks the right
base branch, refuses sync merges, offers backports for fixes, and cuts releases from the
right branch — with no prompting. In a repo without it, every skill behaves exactly as
it does today, apart from a one-line suggestion.

### Decisions made during brainstorming

| Decision                                    | Choice                                                                                                |
| ------------------------------------------- | ----------------------------------------------------------------------------------------------------- |
| Which model a generated `RELEASING.md` uses | Picked per project: **trunk-only** or **trunk + release branches**                                    |
| Scope                                       | Branch-aware PR skills, branch-aware releaser, a new `ycc:backport` skill, hygiene updates            |
| How skills read the state                   | A machine-readable block inside `RELEASING.md`; the human table is rendered from it                   |
| Generator skill name                        | `ycc:release-model` (avoids confusion with `ycc:releaser`)                                            |
| Behavior without `RELEASING.md`             | Unchanged; one-line suggestion only. Never blocks.                                                    |
| `research-to-issues`                        | Out of scope: target-release conventions differ per tracker, so `RELEASING.md` documents them instead |

## 2. The two models

Both models share these rules:

1. The target release is decided before work starts, and the target decides the base branch.
2. Work lands on the trunk in small, short-lived PRs. No long-lived feature branches.
3. Never merge one long-lived branch into another to "sync" it.
4. Unfinished user-visible work stays hidden behind a flag or setting that defaults to off,
   or is not wired in yet. The trunk is always releasable.
5. Releases are tags cut from a branch — never a set of commits picked afterwards.
6. Agents never tag or publish a release unless a maintainer explicitly approves that step.

**Trunk-only.** Every release (major, minor, patch) is tagged from the trunk. A fix ships
in the next release. No maintenance branches, no backports. Suits projects with a single
supported version (most personal projects, services deployed from the trunk).

**Trunk + release branches.** Minor and major releases are tagged from the trunk; each
creates `release/X.Y`. Patches are tagged from `release/X.Y`. A fix that must reach a
shipped minor lands on the trunk first, carries the `backport:X.Y` label, and is
cherry-picked (`-x`) to `release/X.Y` in its own PR. Only the most recent maintenance
branches in the support window receive patches; older ones are frozen.

Switching from trunk-only to release branches is a one-command upgrade
(`/ycc:release-model --upgrade`) and needs no history rewrite.

The canonical text of these rules lives in one shared reference (section 3.1); every
skill links to it instead of restating it.

## 3. Components

### 3.1 Shared reference — `ycc/skills/_shared/references/branching-model.md`

The rules above, both models, the "where does my change go" decision table, the backport
procedure, and the contract for the state block (3.2). Skills cite sections of this file.

### 3.2 State block and rendered table

`RELEASING.md` carries a block that is invisible when rendered:

```markdown
<!-- ycc-release-state
model: release-branches
trunk: master
maintenance: release/0.5
frozen: release/0.4
support: latest-minor
backport_label: backport:{X.Y}
tracker: linear-labels
tracker_ref: tokenhop release
-->
```

Format rules:

- One `key: value` per line; values are plain strings. Lists (`maintenance`, `frozen`) are
  comma-separated, newest first. Empty values are allowed for lists.
- Required keys: `model` (`trunk-only` | `release-branches`), `trunk`.
- Optional keys with defaults: `maintenance` (empty), `frozen` (empty), `support`
  (`latest-minor`; also `latest-two-minors` or free text), `backport_label`
  (`backport:{X.Y}`), `tracker` (`none` | `github-milestones` | `github-labels` |
  `linear-labels`), `tracker_ref` (free text, e.g. a label-group name).
- Unknown keys, a missing required key, an invalid `model`, or `maintenance` set under
  `trunk-only` make the block **malformed**.

The human "Current state" table sits between
`<!-- ycc-release-state:table:begin -->` and `<!-- ycc-release-state:table:end -->` and is
always rendered from the block (trunk, each maintenance branch, frozen branches, support
window). Prose after the end marker is human-owned and never rewritten.

### 3.3 Shared scripts

**`_shared/scripts/release-state.sh [--repo DIR] [get | base [--head REF] | check]`**

- `get` (default) prints `key=value` lines: `present`, `file`, `model`, `trunk`,
  `maintenance`, `latest_maintenance`, `frozen`, `support`, `backport_label`, `tracker`,
  `tracker_ref`. With no `RELEASING.md` it prints `present=0` and exits 0.
- `base` prints the PR base for a head ref (default `HEAD`): `release/X.Y` when the head
  contains commits that are on `origin/release/X.Y` but not on `origin/<trunk>`;
  otherwise the trunk. With no `RELEASING.md` it prints the forge default branch
  (`lib/forge.sh` `forge_default_branch`).
- `check` verifies the table matches the block and that the trunk and maintenance branches
  exist on `origin`. Prints findings; exit 1 if any.
- Exit 2 with a parse error on stderr when the block is malformed.

**`_shared/scripts/release-state-update.sh [--repo DIR] [--dry-run] <op>`**

Ops: `--set-model M`, `--set-trunk B`, `--add-maintenance release/X.Y` (moves branches
outside the support window to `frozen`), `--freeze release/X.Y`, `--render` (re-render the
table only). Rewrites the block and the table together; `--dry-run` prints a unified diff
instead of writing. Never commits.

### 3.4 `RELEASING.md` template

`ycc/skills/release-model/templates/RELEASING.md.tmpl`, one template with per-model
conditional sections, filled in by the skill. Sections:

1. Intro and the core idea.
2. Current state — state block plus rendered table plus a human-owned notes line.
3. Rules (from 3.1, adapted to the model).
4. Where does my change go? — decision table.
5. Unfinished work — flags/settings; the project may list named switches here.
6. Backporting — release-branches model only.
7. Releasing — steps built from detected facts: tag pattern, version files, CHANGELOG,
   CI publish workflow. Minor/major and patch subsections for release-branches.
8. Planning — per tracker: GitHub milestones, GitHub labels, a Linear label group, or none.

### 3.5 New skill — `ycc:release-model` (+ `/ycc:release-model`)

Modes:

- **create** (default when `RELEASING.md` is missing)
  1. `scripts/collect-signals.sh` (read-only) emits `key=value`: default branch; other
     long-lived branches with recent commits; `v*` tags; whether any tag patches an older
     line; GitHub releases; existing `release/*` branches; CI trigger branches and publish
     steps; package/version files; CHANGELOG presence; label taxonomy; Linear usage
     (issue-ID patterns in commits/branches).
  2. Propose a model with the reasons ("release-branches: 3 minors published and a patch on
     an older line" / "trunk-only: no tags yet").
  3. Ask at most three questions: confirm the model, the trunk name, the support window.
     Ask about the tracker only when detection is ambiguous.
  4. Render `RELEASING.md` from the template; add a short "Branching & releases" pointer
     section to `CLAUDE.md` and `AGENTS.md` (and `.github/copilot-instructions.md` when it
     exists); add `backport:X.Y` to the label docs for the release-branches model.
  5. Dry-run preview first, then write. Never commits or pushes; the user ships it as a
     normal PR (for example via `ycc:git-workflow`).
- **`--upgrade`** — trunk-only → release-branches: flips `model`, adds the backporting
  section, and prints the commands to create `release/X.Y` from the latest tag and its
  label.
- **`--audit`** — read-only report: block/table drift; trunk or maintenance branch missing;
  a maintenance `X.Y` with no tag; a minor tag newer than the newest maintenance branch
  (release-branches); long-lived branches; sync merges on the trunk in the last N commits;
  missing `backport:X.Y` labels. Suggests fixes; changes nothing.

Arguments: `[--upgrade | --audit] [--model trunk-only|release-branches] [--trunk NAME]
[--yes]`. `--yes` accepts the proposal without questions (for `init --yes` flows).

### 3.6 New skill — `ycc:backport` (+ `/ycc:backport`)

- **Input:** `<PR#> [--to release/X.Y]` or `--pending` (every merged PR labelled
  `backport:X.Y` with no PR whose body contains "Backport of #N").
- **Per PR:** verify merged and that the target is an active maintenance branch (from the
  state); worktree via `_shared/scripts/setup-worktree.sh` on
  `backport/X.Y/<slug>` from `origin/release/X.Y`; `git cherry-pick -x` of the merge or
  squash commit; push; open a PR with the original title, body "Backport of #N", and the
  original labels minus `backport:*`.
- **Conflicts:** stop and report the files. `--resolve` dispatches a new
  `ycc:backport-conflict-resolver` agent for a minimal resolution, then pauses for review
  before pushing.
- **`--ci`:** watch CI with `_shared/scripts/ci-monitor.sh` and reuse the pr-autofix loop.
- Never merges, tags, or pushes to `release/*` directly.
- Forge support: GitHub via `gh`. Other forges: print the manual commands and stop.
- Scripts: `scripts/find-pending.sh`, `scripts/cherry-pick-pr.sh` (exit 3 on conflict).

## 4. Changes to existing skills

### 4.1 PR and branch skills

- **`_shared/scripts/prepare-feature-branch.sh`** (callers: `prp-implement`,
  `implement-plan`, `orchestrate`, `plan`): when `release-state.sh` reports `present=1`,
  the trunk is the state's `trunk` (in addition to the existing
  `main|master|trunk|develop` list), and a new branch is created from a freshly fetched
  `origin/<trunk>` instead of the current HEAD. On `release/X.Y` it exits 2 with a message
  asking whether this is a release-only fix; `--allow-release-branch` proceeds from there.
  `_shared/references/branch-prep.md` gains the new rows.
- **`git-workflow`** (Phase 5) and **`prp-pr`**:
  - PR base = `release-state.sh base`; new `--base` flag overrides. `prp-pr` drops its
    hard-coded `main` fallback.
  - Sync guard: refuse, citing the rule, when either (a) the head branch is itself
    long-lived (the trunk or a `release/*` branch) and the base is a different long-lived
    branch, or (b) the PR's commits include a merge commit whose second parent is the tip
    of `origin/<trunk>` or of a `release/*` branch. Backport PRs (cherry-picks) are never
    affected, since they contain no merge commits.
  - Backport prompt: under release-branches with at least one maintenance branch, a
    `fix:` change asks "backport to release/X.Y?"; yes adds `backport:X.Y` and prints
    `/ycc:backport <PR#>` for after the merge.
  - Command files (`ycc/commands/git-workflow.md`, `prp-pr.md`) document `--base`.
- **`code-review`**: the context phase reads `RELEASING.md` when present and flags a PR
  whose base contradicts `release-state.sh base`.

### 4.2 Releaser

- Preflight: read the state. Missing → offer `ycc:release-model`, or continue exactly as
  today.
- Branch check: minor/major must be on the trunk; a patch must be on `release/X.Y`
  (release-branches) or the trunk (trunk-only). On `release/X.Y` the version must be
  `X.Y.Z`. A mismatch stops with the exact commands to fix it.
- After a minor/major under release-branches: the emitted commands create `release/X.Y`
  from the tag and the `backport:X.Y` label; `release-state-update.sh --add-maintenance`
  runs before the release commit so the state change ships in it.
- After a patch: print the forward-port step for the CHANGELOG entry to the trunk.
- Phase 8.5 checks protection on the actual release branch instead of hard-coded `main`.
- `references/ci-optimization-checklist.md` accepts `RELEASING.md` as the runbook; the
  `releaser` agent picks this up through the checklist.

### 4.3 Hygiene

- **`git-cleanup`** (skill, `references/active-code-rules.md`, and `ycc/agents/git-cleanup.md`):
  the trunk and active maintenance branches are always protected; a `release/*` not in the
  state is reported as "retired maintenance branch" with an archive-tag suggestion and is
  never deleted without confirmation; branches or merge commits that look like sync merges
  are reported as anti-patterns.
- **`formatters`**: `references/templates/lint.yml.tmpl` pushes on the default branch and
  `release/**`.
- **`init`**: `templates/CLAUDE.md.tmpl` gains a "Branching & releases" pointer section
  (rendered only when `RELEASING.md` exists or is being created); `labels.md.tmpl` gains
  the `backport:X.Y` family; a new phase offers `ycc:release-model` when the file is
  missing; flags `--release-model` / `--no-release-model` (mirrored in
  `ycc/commands/init.md` and `references/flag-reference.md`).
- **`blueprint`**: a release-model question in the interview and a `release_model`
  bootstrap key (`references/bootstrap-mapping.md`) that maps to `init --release-model`.

## 5. Error handling

- Missing `RELEASING.md` never blocks any skill.
- A malformed state block stops every skill that reads it, with the parse error and
  `/ycc:release-model --audit`.
- A state that names a branch missing on `origin` is reported by `check`/`--audit`; skills
  that need that branch (backport, releaser patch) stop with the fix command.
- Network/forge failures in signal collection degrade to "unknown" signals and are listed
  in the proposal instead of failing.

## 6. Testing

- New `scripts/test-release-model.sh`, run by `scripts/validate.sh` as a new `release`
  target (and therefore by CI). It builds throwaway git repos in a temp dir and asserts:
  - `release-state.sh get`: present/missing, both models, defaults, malformed variants
    (exit 2).
  - `release-state.sh base`: trunk head, a head cut from `release/X.Y`, no `RELEASING.md`.
  - `release-state-update.sh`: add/freeze maintenance, support-window rollover, set trunk,
    table re-render, `--dry-run` produces a diff and no write.
  - `collect-signals.sh` on seeded repos: tags only, a patch on an older line, `release/*`
    branches, a long-lived branch, a sync merge.
  - `prepare-feature-branch.sh` branching from `origin/<trunk>` and refusing on
    `release/X.Y`.
  - `find-pending.sh` parsing (with a stubbed `gh`).
- Every phase runs `./scripts/sync.sh` and `./scripts/validate.sh`.
- Dogfooding: run `/ycc:release-model` on this repo (expected: trunk-only) and on a clone
  of 9router (expected: release-branches with `release/0.5`).

## 7. Phasing

One small PR per phase into `main`. Every change is inert without a `RELEASING.md`, so each
phase can ship in any ycc release.

1. **Foundation** — `branching-model.md`, `release-state.sh`, `release-state-update.sh`,
   the `RELEASING.md` template, `test-release-model.sh`, the `validate.sh` target.
2. **`ycc:release-model`** — skill, command, `collect-signals.sh`; dogfood on this repo.
3. **PR and branch skills** — `prepare-feature-branch.sh`, `git-workflow`, `prp-pr`,
   `code-review`.
4. **Releaser** — branch checks, cut-over commands, Phase 8.5, checklist.
5. **`ycc:backport`** — skill, command, scripts, `backport-conflict-resolver` agent with
   its `ycc/settings/models.json` entry.
6. **Hygiene** — `git-cleanup` (skill + agent), `formatters` template, `init`, `blueprint`.

The version bump happens once at the end via `ycc:bundle-release`.

## 8. Out of scope

- `research-to-issues` target-release labels.
- Automatic conflict resolution without review.
- Forges other than GitHub for `ycc:backport` (manual commands are printed).
- Rewriting existing projects' history or branches; `--upgrade` only prints branch commands.
