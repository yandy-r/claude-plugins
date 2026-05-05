---
name: prp-pr
description: Create a GitHub pull request from the current branch — validates preconditions, discovers PR templates, analyzes commits and file diffs, references PRP artifacts (prds/plans/reports), pushes, and creates the PR via gh. Lightweight sibling of /git-workflow --pr; use this when you only need the PR, not the commit+docs orchestration. Adapted from PRPs-agentic-eng by Wirasm.
argument-hint: '[base-branch] [--draft] [--ci] [--ci-max-pushes=N] [--ci-max-same-failure=N] [--ci-timeout-min=N] [--ci-yes]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Bash(git:*)
  - Bash(gh:*)
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(find:*)
  - 'mcp__github__*'
---

# Create Pull Request

> Adapted from PRPs-agentic-eng by Wirasm. Part of the PRP workflow series.

**Input**: `$ARGUMENTS` — optional, may contain a base branch name and/or flags (e.g., `--draft`).

This is the lightweight counterpart to `/git-workflow --pr`. Use it when you just need the PR created, without the full commit+documentation orchestration.

**Parse `$ARGUMENTS`**:

- Extract any recognized flags:
  - `--draft` — create the PR as a draft
  - `--ci` — after PR creation, enter the bounded CI auto-fix loop (Phase 7)
  - `--ci-max-pushes=N` — hard cap on autonomous pushes per invocation (default: 5)
  - `--ci-max-same-failure=N` — bail after the same failure signature recurs N times (default: 3)
  - `--ci-timeout-min=N` — wall-clock cap in minutes from the first CI iteration (default: 30)
  - `--ci-yes` — skip the one-time authorization prompt (for non-interactive callers)
- Treat remaining non-flag text as the base branch name
- Default base branch to `main` if none specified

---

## Phase 1 — VALIDATE

Check preconditions:

```bash
git branch --show-current
git status --short
git log origin/<base>..HEAD --oneline
```

| Check                   | Condition                                           | Action if Failed                                                                              |
| ----------------------- | --------------------------------------------------- | --------------------------------------------------------------------------------------------- |
| Not on base branch      | Current branch ≠ base                               | Stop: "Switch to a feature branch first."                                                     |
| Clean working directory | No uncommitted changes                              | Warn: "You have uncommitted changes. Commit or stash first. Use `/prp-commit` to commit." |
| Has commits ahead       | `git log origin/<base>..HEAD` not empty             | Stop: "No commits ahead of `<base>`. Nothing to PR."                                          |
| No existing PR          | `gh pr list --head <branch> --json number` is empty | Stop: "PR already exists: #<number>. Use `gh pr view <number> --web` to open it."             |

If any check that stops execution fires and `--ci` was passed, append to the stop
message: `--ci will not run because no PR will be created.`

**PR already exists — `--ci` continuation:** If `gh pr list --head <branch>` finds
an existing open PR and `--ci` was passed, instead of stopping, prompt:
`PR #<num> already exists. Run --ci against it? (yes/no)`. On `yes`, record the
existing PR number and skip Phases 2–4 (no new PR is created), then proceed
directly to Phase 5 (VERIFY) and Phase 7 (CI Monitoring). On `no`, exit cleanly
with: `CI monitoring declined; PR already exists and was not monitored.`

If all checks pass, proceed.

---

## Phase 2 — DISCOVER

### PR Template

Search for PR template in order:

1. `.github/PULL_REQUEST_TEMPLATE/` directory — if exists, list files and let user choose (or use `default.md`)
2. `.github/PULL_REQUEST_TEMPLATE.md`
3. `.github/pull_request_template.md`
4. `docs/pull_request_template.md`

If found, read it and use its structure for the PR body.

### Commit Analysis

```bash
git log origin/<base>..HEAD --format="%h %s" --reverse
```

Analyze commits to determine:

- **PR title**: Use conventional commit format with type prefix — `feat: ...`, `fix: ...`, etc.
  - If multiple types, use the dominant one
  - If single commit, use its message as-is
- **Change summary**: Group commits by type/area

### File Analysis

```bash
git diff origin/<base>..HEAD --stat
git diff origin/<base>..HEAD --name-only
```

Categorize changed files: source, tests, docs, config, migrations.

### PRP Artifacts

Check for related PRP artifacts:

- `docs/prps/reports/` — Implementation reports
- `docs/prps/plans/` — Plans that were executed (including the `completed/` subfolder)
- `docs/prps/prds/` — Related PRDs

Reference these in the PR body if they exist.

---

## Phase 3 — PUSH

Detect whether GitHub MCP tools are available (look for `mcp__github__*`). If they are, prefer those for push-related operations. Otherwise fall back to the `gh` CLI and `git` over Bash.

```bash
git push -u origin HEAD
```

If push fails due to divergence:

```bash
git fetch origin
git rebase origin/<base>
git push -u origin HEAD
```

If rebase conflicts occur, stop and inform the user.

---

## Phase 4 — CREATE

### With Template

If a PR template was found in Phase 2, fill in each section using the commit and file analysis. Preserve all template sections — leave sections as "N/A" if not applicable rather than removing them.

### Without Template

Use this default format:

```markdown
## Summary

<1-2 sentence description of what this PR does and why>

## Changes

<bulleted list of changes grouped by area>

## Files Changed

<table or list of changed files with change type: Added/Modified/Deleted>

## Testing

<description of how changes were tested, or "Needs testing">

## PRP Artifacts

<links to docs/prps/prds|plans|reports referenced by this work, or "None">

## Related Issues

<linked issues with Closes/Fixes/Relates to #N, or "None">
```

### Create the PR

```bash
gh pr create \
  --title "<PR title>" \
  --base <base-branch> \
  --body "<PR body>"
  # Add --draft if the --draft flag was parsed from $ARGUMENTS
```

---

## Phase 5 — VERIFY

```bash
gh pr view --json number,url,title,state,baseRefName,headRefName,additions,deletions,changedFiles
gh pr checks --json name,status,conclusion 2>/dev/null || true
```

---

## Phase 6 — OUTPUT

Report to user:

```
PR #<number>: <title>
URL: <url>
Branch: <head> → <base>
Changes: +<additions> -<deletions> across <changedFiles> files

CI Checks: <status summary or "pending" or "none configured">

Artifacts referenced:
  - <any PRP reports/plans linked in PR body>

Next steps:
  - gh pr view <number> --web      → open in browser
  - /code-review <number>      → review the PR
  - gh pr merge <number>           → merge when ready
```

---

## Phase 7: CI Monitoring (Optional, `--ci` flag)

**Trigger:** Runs ONLY when `--ci` was passed AND a PR is in scope (created in
Phase 4, or an existing PR confirmed for monitoring per the Phase 1 modification
above). Skip silently otherwise.

**Step 1 — Verify PR is monitorable:** Confirm a PR number is in scope. If not,
hard-stop: `--ci was passed but no PR is in scope to monitor.`

**Step 2 — Load policy reference:** Read
`${CURSOR_PLUGIN_ROOT}/skills/_shared/references/ci-monitoring.md` to load the
failure classification table, termination policy, audit log schema, and loop
protocol. That file is authoritative — do not restate its contents here.

**Step 3 — One-time authorization prompt** (skip if `--ci-yes`):

```
CI auto-fix loop authorization
==============================
PR:                 #<pr_number> (<head_branch> → <base_branch>)
Max auto-pushes:    <resolved --ci-max-pushes>
Max same failure:   <resolved --ci-max-same-failure>
Wall-clock timeout: <resolved --ci-timeout-min> minutes
Audit log:          ~/.cursor/session-data/ci-watch/<pr>-<timestamp>.log

Safety constraints (non-toggleable):
  - Never `git push --force`
  - Never `--no-verify`
  - Only push to PR head branch
  - Refuse if head equals default branch

Proceed? (yes/no):
```

On `no`: `CI monitoring declined; PR was created but not monitored.` Exit cleanly.

**Step 4 — Initialize audit log:** Create `~/.cursor/session-data/ci-watch/` if
absent. Compute log path `~/.cursor/session-data/ci-watch/<pr>-<utc-iso-timestamp>.log`.
Reuse this path for every iteration in the session.

**Step 5 — Loop iteration:** Invoke:

```bash
${CURSOR_PLUGIN_ROOT}/skills/_shared/scripts/ci-monitor.sh \
  --pr <pr_number> \
  --branch <head_branch> \
  --base <base_branch> \
  --max-pushes <N> \
  --max-same-failure <N> \
  --timeout-min <N> \
  --log-file <audit_log_path>
```

Branch on stdout `RESULT=...` per the Loop Protocol in `ci-monitoring.md`:

- `green` → Go to Step 6 (success).
- `handoff` → Read `RUN_ID`, `WORKFLOW`, `JOB`, `CATEGORY`, `SIGNATURE`,
  `LOG_EXCERPT_FILE`, `SUGGESTED_COMMIT_TYPE`, `SUGGESTED_COMMIT_SCOPE`. Apply
  fix per the Failure Classification table for `CATEGORY` (defined in
  `ci-monitoring.md`). Validate commit message via
  `${CURSOR_PLUGIN_ROOT}/skills/git-workflow/scripts/validate-commit.sh`. Commit
  and push to head branch (NEVER `--force`, NEVER `--no-verify`). Goto Step 5.
- `rerun-pending` → Flake-suspected; script already triggered rerun. Sleep 30s,
  goto Step 5 (do NOT apply any fix).
- `bail-*` → Go to Step 6 (diagnosis). Do not push further.
- `pr-not-found` / `refused-default-branch` → Surface the error; do not retry.

**Step 6 — Final report:**

On `green`:

```
✓ CI green for PR #<pr> after <iterations> iteration(s), <pushes> auto-push(es).
  Audit log: <path>
```

On bail:

```
✗ CI monitoring ended: <RESULT> — <REASON>
  Cap fired: <which cap or constraint>
  Audit log: <path>
```

See `${CURSOR_PLUGIN_ROOT}/skills/_shared/references/ci-monitoring.md` for the
full policy.

---

## Edge Cases

- **No `gh` CLI**: Stop with: "GitHub CLI (`gh`) is required. Install: <https://cli.github.com/>"
- **Not authenticated**: Stop with: "Run `gh auth login` first."
- **Force push needed**: If remote has diverged and rebase was done, use `git push --force-with-lease` (never `--force`).
- **Multiple PR templates**: If `.github/PULL_REQUEST_TEMPLATE/` has multiple files, list them and ask user to choose.
- **Large PR (>20 files)**: Warn about PR size. Suggest splitting if changes are logically separable.

---

## When to use this vs `/git-workflow --pr`

| Use `/prp-pr` when            | Use `/git-workflow --pr` when                  |
| --------------------------------- | -------------------------------------------------- |
| Your commits are already in place | You want to commit and PR in one flow              |
| You want a focused PR-only tool   | You want documentation agents to update docs first |
| You want minimal orchestration    | You have many files touching docs + code           |
| `--ci` needed (identical support) | `--ci` needed (identical support)                  |
