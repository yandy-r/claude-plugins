---
name: git-cleanup
description: This skill should be used when the user asks to "clean up git", "prune
  stale branches", "clean up worktrees", "close stale PRs/issues", "tidy up my repo",
  or mentions removing abandoned branches, worktrees, remote-tracking refs, tags,
  stashes, PRs, or issues on GitHub/GitLab. Analyzes active code before recommending
  deletions, presents a plan, and only acts after explicit approval. Dry-run and read-only
  audit by default.
---

# git-cleanup

Audit and clean up stale git resources — local branches, remote-tracking refs,
worktrees, stashes, tags, pull requests, and issues — across local checkouts,
GitHub, and GitLab. Before recommending any deletion, the skill cross-references
active code and project state to distinguish truly abandoned resources from
work-in-progress. **Dry-run is the default; destructive actions require `--apply`
plus explicit user confirmation.**

## Arguments

Parse `$ARGUMENTS`:

- **--dry-run** (default): Analyze and report only. Never deletes.
- **--apply**: Enable destructive actions. Still requires interactive confirmation.
- **--report-only**: Write the audit report and stop; skip the decision prompt.
- **--branches** / **--worktrees** / **--remotes** / **--stashes** / **--tags** /
  **--prs** / **--issues**: Limit scope to the listed domains. Default is all
  local domains (branches, worktrees, remotes, stashes, tags) plus remote
  domains (prs, issues) when a host CLI is available.
- **--stale-days=N**: Age threshold for "stale" (default: 90).
- **--host=github|gitlab|auto**: Remote host. `auto` (default) parses `origin`.
- **--protect=<pattern>** (repeatable): Extra branch patterns that must never be
  deleted. Always-protected: `main`, `master`, `develop`, the default branch,
  and any branch that is the base of an open PR.

## Phase 0: Setup and Host Detection

1. **Verify working tree is a git repo**: `git rev-parse --git-dir`. Abort if not.
2. **Determine default branch**: `git symbolic-ref refs/remotes/origin/HEAD` →
   fall back to `main` / `master` if unset.
3. **Detect host CLIs and MCP tools**. See
   `~/.codex/plugins/ycc/skills/git-cleanup/references/host-detection.md` for
   the full decision table. Summary:
   - Prefer `mcp__github__*` tools if available for GitHub operations.
   - Else `gh auth status` for GitHub, `glab auth status` for GitLab.
   - If `--host=auto`, parse `git remote get-url origin`. Unknown hosts skip
     the remote-domain audits with a loud notice.
4. **Check working-tree state**: Capture `git status --porcelain` and
   `git stash list`. Record whether the current branch has unpushed commits.
5. **Initialize progress tracking** with the task tracker (one entry per phase).
6. **Create audit directory**: `.git-cleanup/` at the repo root. Report and
   per-domain finding files land here.
7. **If `--dry-run` was passed alongside `--apply`**: Abort — they conflict.

## Phase 1: Collect Raw Git State

Run only commands needed for the requested scope. Prefer porcelain / `--format`
flags that emit machine-readable output.

- **Branches**: `git for-each-ref refs/heads/ --format='%(refname:short)|%(upstream)|%(upstream:track)|%(committerdate:iso8601)|%(objectname)'`
- **Remote-tracking prune candidates**: `git remote prune <remote> --dry-run`
  for each remote from `git remote`.
- **Worktrees**: `git worktree list --porcelain`. Flag entries whose `worktree`
  path no longer exists, whose branch is `[gone]`, or which sit inside a repo
  (`<repo>/.codex/worktrees/`) instead of `~/.claude-worktrees/`.
- **Stashes**: `git stash list --date=iso`. Parse the date from each entry.
- **Tags**: `git for-each-ref refs/tags/ --format='%(refname:short)|%(creatordate:iso8601)|%(objectname)'`
  then `git ls-remote --tags <remote>` to find local-only tags.
- **PRs** (when host available): List merged-but-branch-still-local and stale
  open PRs authored by the current user. Example GitHub via `gh`:
  `gh pr list --state=all --author=@me --json number,title,state,headRefName,baseRefName,updatedAt,isDraft,mergedAt,closedAt`.
- **Issues** (when host available): `gh issue list --state=open --author=@me --json number,title,updatedAt,labels`
  filtered by `updatedAt < now - stale-days`.

## Phase 2: Active-Code Analysis

This is the gating phase. **Never** recommend deletion of a resource that
Phase 2 flags as active. See
`~/.codex/plugins/ycc/skills/git-cleanup/references/active-code-rules.md` for
rule rationales, edge cases, and the full decision matrix.

For each candidate branch, worktree, PR, and issue, mark as **active** if any
of the following is true:

1. **Recent commits**: Tip commit is newer than `stale-days` days.
2. **Unpushed work**: The local branch has commits not in its upstream (or no
   upstream is configured and commits are ahead of the default branch).
3. **Uncommitted / stashed changes**: For worktrees — dirty working tree
   (`git -C <worktree> status --porcelain` non-empty) or a stash attached to
   the branch.
4. **Referenced in open PR**: The branch is the `headRef` of any open PR, OR
   the `baseRef` of an open PR (never touch a base branch).
5. **Referenced in active code**: Grep the tracked working tree for the branch
   name — `git grep -l -w <branch-name>` — in docs, issue templates, CI config,
   release notes, and comments. A textual reference in tracked files means the
   branch is load-bearing.
6. **Linked to active issues**: PR/issue body references an open issue updated
   within `stale-days`, or has the `status:in-progress` / `status:needs-info`
   label family defined by this repo's taxonomy.
7. **Protected name**: Matches `main|master|develop`, the default branch, or
   any `--protect=<pattern>`.
8. **Recent reflog activity**: `git reflog show <branch>` shows motion within
   `stale-days`.

Candidates that fail every check become **stale** — eligible for cleanup.
Record the reason per candidate so the user can audit the decision.

## Phase 3: Produce the Audit Report

Write `.git-cleanup/report.md` with sections keyed by domain:

- **Protected** — always-kept resources and why (default branch, open-PR bases,
  user-protected patterns).
- **Active (skip)** — candidates gated out by Phase 2, each with the specific
  rule that matched.
- **Stale (eligible)** — candidates safe to clean, grouped by domain, with the
  exact `git` / `gh` / `glab` command that would remove each one.
- **Ambiguous (ask)** — edge cases (e.g., branch has unpushed commits **and**
  hasn't been touched in 6 months; worktree with clean tree but branch `[gone]`).
- **Host-API notes** — PRs/issues surfaced from GitHub/GitLab with current
  state and decision rationale.

Also emit a one-screen summary to stdout: counts per category and the path to
the full report. If `--report-only`, **STOP** here.

## Phase 4: User Decision Gate

Present the summary via ask the user. Offer structured choices:

- **View full report** — print `.git-cleanup/report.md` in chunks.
- **Apply all stale (skip ambiguous)**.
- **Apply all stale + resolve ambiguous interactively**.
- **Choose per domain** — branches only, worktrees only, etc.
- **Cancel** — exit without changes.

For ambiguous items, re-prompt per item with the evidence summary and the
exact command that would run.

If `--dry-run` is active (default), **STOP** here — do not invoke Phase 5 even
if the user clicks "Apply". Tell them to rerun with `--apply`.

## Phase 5: Execute (only with `--apply`)

For each approved item, in this order (safest first):

1. **Remote-tracking prune**: `git remote prune <remote>`.
2. **Worktrees**: `git worktree remove <path>`. If missing on disk, use
   `git worktree prune`.
3. **Local branches**: `git branch -d <name>` (never `-D` unless the branch
   has been merged to the default branch or its upstream is `[gone]` AND the
   user explicitly confirmed in Phase 4).
4. **Local-only tags**: `git tag -d <name>`.
5. **Stashes**: `git stash drop stash@{N}`. Drop highest-indexed first to keep
   indices stable during the sweep.
6. **PRs**: close via host CLI / MCP (`gh pr close` or GitLab equivalent). Add
   a closing comment referencing staleness if repo conventions require one.
7. **Issues**: close with a stale-label comment or add a `wontfix` / stale
   label from the repo's taxonomy — never invent ad-hoc labels.

Record each action (success / failure / skipped) in `.git-cleanup/actions.log`.
On any individual failure: log and continue. On systemic failure (e.g., auth
error): abort and report.

## Phase 6: Verification and Summary

1. **Re-run Phase 1 collection** for the targeted domains and diff against the
   pre-execution snapshot. Confirm each approved item is gone.
2. **Print final summary**: counts removed per domain, any skipped items with
   reason, and the paths to `.git-cleanup/report.md` and `actions.log`.
3. **Do NOT commit** anything automatically — cleanup output lives under
   `.git-cleanup/` which should be added to `.gitignore` by the user.

## Host-Specific Notes

- **GitHub**: Prefer `mcp__github__*` tools when present. Fall back to `gh`.
  Use `gh pr list --search` for richer stale-age filters when supported.
- **GitLab**: Use `glab` with equivalent subcommands (`glab mr list`,
  `glab issue list`). Self-hosted GitLab URLs resolve via `glab` config.
- **Neither CLI available**: Skip `--prs` and `--issues` domains with a loud
  notice; local cleanup still proceeds.

## Subagent Delegation

For large repos where Phase 2's active-code scan is expensive, delegate to
`git-cleanup` agent via the parallel agent workflow. The agent performs the read-only
audit (Phases 1-3) and returns a structured report; this skill orchestrates
Phases 4-6.

## Important Notes

- **Dry-run by default**. Destruction requires `--apply` **and** interactive
  approval.
- **Never touch the default branch, protected branches, or open-PR bases.**
- **Never `git branch -D`** without explicit per-item confirmation.
- **Worktrees under `~/.claude-worktrees/`** are fair game per this repo's
  convention; worktrees inside a repo at `<repo>/.codex/worktrees/` should
  also be reported and, if the user confirms, relocated or removed.
- **Respect the repo's label taxonomy**. Do not invent stale/wontfix labels.
- **No secrets**. Do not log tokens or API responses containing credentials.
- **Ambiguous items are always surfaced**, never auto-deleted.
