# Branch Prep Helper Contract

Use `prepare-feature-branch.sh` before any worktree setup or implementor-agent dispatch, except in dry-run or plan-only paths that do not touch git. Worktree setup adopts the prepared `feat/<slug>` branch when it exists.

```bash
FEATURE_BRANCH=$(bash ${CURSOR_PLUGIN_ROOT}/skills/_shared/scripts/prepare-feature-branch.sh "${FEATURE_SLUG}")
```

The helper echoes the prepared branch name on success.

| Current State                                                                  | Helper Behavior                                                                       |
| ------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------- |
| On `feat/<slug>`                                                               | Idempotent no-op; echoes branch and exits 0                                           |
| On `main`/`master`/`trunk`/`develop`, clean or plan-only dirty, branch exists  | `git checkout feat/<slug>`; echoes branch                                             |
| On `main`/`master`/`trunk`/`develop`, clean or plan-only dirty, branch missing | `git checkout -b feat/<slug>`; echoes branch                                          |
| On another feature branch                                                      | Exits 2; re-run with `--allow-existing-feature-branch` after confirming with the user |
| On trunk with unrelated dirty files                                            | Exits 1; stop and ask the user to stash or commit first                               |

If the helper exits 2, surface the message to the user, ask whether to reuse the current branch, and re-invoke with `--allow-existing-feature-branch` on confirmation.

If it exits 1, stop and have the user clean the tree before dispatching agents.
