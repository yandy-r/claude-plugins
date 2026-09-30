---
description: Cherry-pick merged trunk PRs onto active maintenance branches (release/X.Y) and open backport PRs, following RELEASING.md and its backport:X.Y labels. Stops on conflicts unless --resolve; optional CI loop with --ci.
argument-hint: '<PR#> [--to release/X.Y] | --pending [--resolve] [--ci] [--dry-run]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - Agent
  - Task
  - AskUserQuestion
  - TodoWrite
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - Bash(mktemp:*)
  - Bash(date:*)
  - Bash(git:*)
  - Bash(gh:*)
  - Bash(jq:*)
  - Bash(bash:*)
  - Bash(npm:*)
  - Bash(pnpm:*)
  - Bash(yarn:*)
  - Bash(bun:*)
  - Bash(npx:*)
  - Bash(cargo:*)
  - Bash(go:*)
  - Bash(make:*)
---

# Backport Command

Cherry-pick a merged trunk PR (or every pending labelled PR) onto the project's active
maintenance branches and open one backport PR per target.

**Load and follow the `ycc:backport` skill, passing through `$ARGUMENTS`.**

Requires a `RELEASING.md` using the `release-branches` model (create one with
`/ycc:release-model`). GitHub only; on other forges the skill prints the manual commands.

## Input forms

| Input       | Meaning                                                                                 |
| ----------- | --------------------------------------------------------------------------------------- |
| `<PR#>`     | A merged trunk PR: number, `#N`, or GitHub PR URL.                                      |
| `--pending` | Every merged PR with a `backport:X.Y` label and no PR whose body says `Backport of #N`. |

## Flags

| Flag               | Effect                                                                                                   |
| ------------------ | -------------------------------------------------------------------------------------------------------- |
| `--to release/X.Y` | Target branch (repeatable). Default: the PR's `backport:X.Y` labels, else the latest maintenance branch. |
| `--resolve`        | On conflict, dispatch `ycc:backport-conflict-resolver`, show the diff, and ask before continuing.        |
| `--ci`             | Watch each backport PR's CI and run the bounded auto-fix loop (same policy as `/ycc:pr-autofix --ci`).   |
| `--dry-run`        | Print the plan and commands only. No worktree, push, or PR.                                              |

Only active maintenance branches (the `maintenance` list in `RELEASING.md`) are targets;
labels for frozen branches are reported and skipped.

## What the command never does

- Merge a PR, create a tag, or push to `release/*` or the trunk. It pushes only the
  `backport/X.Y/<pr>-<slug>` branch it created.
- `git push --force` or `--no-verify`.
- Continue past a conflict resolution without showing the diff and asking.

## Usage

```
/ycc:backport 142                        # labels decide the targets
/ycc:backport 142 --to release/0.5       # explicit target
/ycc:backport --pending --dry-run        # what still needs backporting
/ycc:backport --pending --resolve --ci   # backport everything, resolve conflicts, watch CI
```

## Related

| Skill                | Role                                                                |
| -------------------- | ------------------------------------------------------------------- |
| `/ycc:release-model` | Creates `RELEASING.md` and the maintenance-branch state this reads. |
| `/ycc:releaser`      | Cuts the patch release from `release/X.Y` after backports merge.    |
| `/ycc:pr-autofix`    | Shares the `--ci` loop and fixer agent.                             |
