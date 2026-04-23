---
description: 'Fast interactive review of uncommitted changes. Findings print inline
  and writes nothing by default. Apply fixes hands findings directly to /quick-fix.
  Save to file writes an artifact and stops. Write file and apply fixes uses /review-fix.
  Pass --parallel or --team for 3-reviewer fan-out; --yes, --save, or --write-and-apply
  for scripted choices. Usage: [--parallel | --team] [--yes | --save | --write-and-apply]
  [--severity <level>] [--no-worktree]'
---

# Quick Review Command

Run a fast, inline, interactive review of uncommitted changes.

**Load and follow the `quick-review` skill, passing through `$ARGUMENTS`.**

Unlike `/code-review`, this skill:

- Prints findings **inline** — no artifact is written by default
- Asks **Apply fixes / Save to file / Discard** after normal reviews
- Adds **Write file and apply fixes** for larger reviews (`5+` findings or `3+`
  finding files)
- Hands direct **Apply fixes** to `/quick-fix` without writing a file
- Uses `/review-fix` only for explicit artifact-backed fixing

Designed for short, low-friction code changes where opening a full
`/code-review` artifact is overkill.

**Flags**:

- `--parallel` — Fan out the REVIEW phase across 3 standalone
  `code-reviewer` sub-agents (correctness, security, quality) in parallel.
  Works in opencode, Cursor, and Codex bundles.

- `--team` — (Claude Code only) Same 3-reviewer fan-out as `--parallel`,
  dispatched as a coordinated agent team with `spawn coordinated subagents`, shared `the todo tracker`,
  per-reviewer task tracking, and coordinated shutdown before merge. Cursor and
  Codex bundles lack the team tools — use `--parallel` there instead.

- `--yes` — Skip the confirmation prompt and auto-confirm **Apply fixes**.
  This invokes `/quick-fix` directly and writes no artifact. Mutually
  exclusive with `--save` and `--write-and-apply`.

- `--save` — Skip the confirmation prompt and auto-confirm **Save to file**
  (writes the artifact and exits; does not run a fixer). Mutually exclusive
  with `--yes` and `--write-and-apply`.

- `--write-and-apply` — Skip the confirmation prompt, write the artifact, then
  invoke `/review-fix`. This is the explicit old artifact-backed apply
  path. Mutually exclusive with `--yes` and `--save`.

- `--severity <CRITICAL|HIGH|MEDIUM|LOW>` — Minimum severity threshold forwarded
  to `/quick-fix` or `/review-fix` during hand-off. Default: `HIGH`.
  Ignored on "Save to file" and "Discard".

- `--no-worktree` — Accepted as a **no-op**. Quick mode never creates a worktree.

```
Usage: /quick-review [--parallel | --team] [--yes | --save | --write-and-apply] [--severity <level>] [--no-worktree]

Examples:
  /quick-review                               # inline review, prompt for confirmation
  /quick-review --parallel                    # 3 parallel sub-agent reviewers, prompt for confirmation
  /quick-review --team                        # 3-reviewer agent team (Claude Code only), prompt for confirmation
  /quick-review --yes                         # auto-confirm: direct /quick-fix, no artifact
  /quick-review --save                        # auto-confirm: write artifact + exit
  /quick-review --write-and-apply             # write artifact + invoke /review-fix
  /quick-review --yes --severity MEDIUM       # direct quick-fix with lower threshold
  /quick-review --parallel --yes              # parallel review + direct quick-fix
```

The skill will:

1. `git diff --name-only HEAD` — abort if nothing is changed
2. REVIEW — single-pass, `--parallel`, or `--team` dispatch
3. Print findings **inline** in Review Artifact Format (no file written yet)
4. Ask for the action, adding an artifact-backed option for large reviews
5. Invoke `/quick-fix` for direct apply, or `/review-fix` only after an
   explicit artifact write

`/code-review --quick` delegates here. Use this command directly to access
`--yes`, `--save`, `--write-and-apply`, and `--severity`.
