---
description: 'Audit and clean up stale git resources (branches, worktrees, remote-tracking
  refs, stashes, tags, PRs, issues) on GitHub/GitLab. Cross-references active code
  before recommending deletions. Dry-run by default. Usage: [--dry-run|--apply] [--branches]
  [--worktrees] [--remotes] [--stashes] [--tags] [--prs] [--issues] [--stale-days=N]
  [--host=github|gitlab|auto] [--protect=<pattern>] [--report-only]'
---

Invoke the **git-cleanup** skill to audit and optionally remove stale git
resources. Cross-references active code (recent commits, unpushed work,
in-tree references, open-PR bases) before proposing any deletions.

The skill:

1. Detects host (GitHub via `gh`/MCP, GitLab via `glab`) and collects raw git
   state for the requested domains.
2. Runs an active-code analysis pass that gates out anything in use — recent
   commits, unpushed work, referenced in tracked files, base of an open PR,
   protected branch, linked to an active issue.
3. Writes an audit report to `.git-cleanup/report.md` (protected / active /
   stale / ambiguous / host-API notes).
4. Presents a summary and asks for per-domain or per-item approval.
5. **Only** with `--apply` and explicit approval, executes deletions safest
   first (prune → worktrees → branches → tags → stashes → PRs → issues) and
   logs every action to `.git-cleanup/actions.log`.

## Flags

- `--dry-run` (default) — analyze and report only.
- `--apply` — enable destructive actions (still gated behind user approval).
- `--report-only` — write the report and stop; skip the decision prompt.
- `--branches` / `--worktrees` / `--remotes` / `--stashes` / `--tags` /
  `--prs` / `--issues` — scope the audit to one or more domains.
- `--stale-days=N` — age threshold for "stale" (default: 90).
- `--host=github|gitlab|auto` — remote host (default: auto from `origin`).
- `--protect=<pattern>` — extra branch patterns that must never be deleted
  (repeatable; combines with `main|master|develop` + default branch +
  open-PR bases, which are always protected).

## Examples

```
/git-cleanup                                 # full audit, dry-run
/git-cleanup --report-only                   # write report and exit
/git-cleanup --branches --worktrees          # local only
/git-cleanup --prs --issues --stale-days=60  # hosted side only
/git-cleanup --apply                         # interactive cleanup
/git-cleanup --apply --branches --protect='release/*'
```

## Related

- `/clean` — project **file** cleanup (build artifacts, unused code). Not
  git state.
- `/git-workflow` — commit, push, and PR **creation**. Complement, not
  overlap.
- `commit-commands:clean_gone` — quick purge of `[gone]` local branches. Use
  it for a fast one-liner; use `/git-cleanup` when you want the full
  audit + host-side resources.
