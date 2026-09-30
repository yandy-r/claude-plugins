---
description: 'Create, upgrade, or audit a project''s RELEASING.md branching and release
  model — surveys tags, release branches, CI, and version files, proposes trunk-only
  or release-branches, renders RELEASING.md with a machine-readable state block, and
  adds pointer sections to AGENTS.md and AGENTS.md. Dry-run preview first; never commits
  or pushes. Usage: [--upgrade | --audit] [--model trunk-only|release-branches] [--trunk
  NAME] [--yes]'
---

Invoke the **release-model** skill with `$ARGUMENTS` passed through.

## Modes

| Invocation                     | Mode    | What happens                                                                                   |
| ------------------------------ | ------- | ---------------------------------------------------------------------------------------------- |
| `/release-model`           | create  | No `RELEASING.md`: survey the repo, propose a model, ask up to three questions, preview, write |
| `/release-model`           | audit   | `RELEASING.md` exists: same as `--audit`                                                       |
| `/release-model --upgrade` | upgrade | trunk-only → release-branches; keeps human prose; prints the `release/X.Y` cut-over commands   |
| `/release-model --audit`   | audit   | Read-only report: state drift, missing branches or labels, long-lived branches, sync merges    |

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
/release-model                              # create (or audit when RELEASING.md exists)
/release-model --model trunk-only --yes     # non-interactive create, e.g. from /init
/release-model --model release-branches --trunk master
/release-model --upgrade                    # start maintaining release/X.Y branches
/release-model --audit
```

## Related

- `/releaser` — cuts releases from the branch `RELEASING.md` names.
- `/git-workflow`, `/prp-pr` — pick the PR base from `RELEASING.md`.
- `/init` — offers this command when `RELEASING.md` is missing.

The model's rules live in `.opencode-plugin/skills/_shared/references/branching-model.md`. This
command never commits, pushes, tags, or creates branches or labels; ship the result with
`/git-workflow`.
