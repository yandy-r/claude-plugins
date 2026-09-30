---
description: Create, upgrade, or audit a project's RELEASING.md branching and release model — surveys tags, release branches, CI, and version files, proposes trunk-only or release-branches, renders RELEASING.md with a machine-readable state block, and adds pointer sections to CLAUDE.md and AGENTS.md. Dry-run preview first; never commits or pushes.
argument-hint: '[--upgrade | --audit] [--model trunk-only|release-branches] [--trunk NAME] [--yes]'
---

Invoke the **release-model** skill with `$ARGUMENTS` passed through.

## Modes

| Invocation                     | Mode    | What happens                                                                                   |
| ------------------------------ | ------- | ---------------------------------------------------------------------------------------------- |
| `/ycc:release-model`           | create  | No `RELEASING.md`: survey the repo, propose a model, ask up to three questions, preview, write |
| `/ycc:release-model`           | audit   | `RELEASING.md` exists: same as `--audit`                                                       |
| `/ycc:release-model --upgrade` | upgrade | trunk-only → release-branches; keeps human prose; prints the `release/X.Y` cut-over commands   |
| `/ycc:release-model --audit`   | audit   | Read-only report: state drift, missing branches or labels, long-lived branches, sync merges    |

## Flags

| Flag                                   | Effect                                                                         |
| -------------------------------------- | ------------------------------------------------------------------------------ |
| `--upgrade`                            | Move an existing trunk-only model to release-branches                          |
| `--audit`                              | Report only; change nothing (mutually exclusive with `--upgrade`)              |
| `--model trunk-only\|release-branches` | Preselect the model in create mode; skips that question                        |
| `--trunk NAME`                         | Preselect the trunk branch; skips that question                                |
| `--yes`                                | Accept the proposal without questions; still prints the preview before writing |

## Examples

```text
/ycc:release-model                              # create (or audit when RELEASING.md exists)
/ycc:release-model --model trunk-only --yes     # non-interactive create, e.g. from /ycc:init
/ycc:release-model --model release-branches --trunk master
/ycc:release-model --upgrade                    # start maintaining release/X.Y branches
/ycc:release-model --audit
```

## Related

- `/ycc:releaser` — cuts releases from the branch `RELEASING.md` names.
- `/ycc:git-workflow`, `/ycc:prp-pr` — pick the PR base from `RELEASING.md`.
- `/ycc:init` — offers this command when `RELEASING.md` is missing.

The model's rules live in `ycc/skills/_shared/references/branching-model.md`. This
command never commits, pushes, tags, or creates branches or labels; ship the result with
`/ycc:git-workflow`.
