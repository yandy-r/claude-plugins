---
description: 'Fast interactive review of uncommitted changes — findings print inline;
  Apply fixes / Save to file / Discard on confirmation. Writes nothing by default.
  Hands off to /review-fix on "Apply fixes". Pass --parallel or --team for 3-reviewer
  fan-out. Pass --yes or --save to skip the prompt (scripted use). Pass --severity
  <CRITICAL|HIGH|MEDIUM|LOW> to forward the minimum-severity threshold to /review-fix
  (default HIGH). Usage: [--parallel | --team] [--yes | --save] [--severity <level>]
  [--no-worktree]'
---

# Quick Review Command

Run a fast, inline, interactive review of uncommitted changes.

**Load and follow the `quick-review` skill, passing through `$ARGUMENTS`.**

Unlike `/code-review`, this skill:

- Prints findings **inline** — no artifact is written by default
- Asks **Apply fixes / Save to file / Discard** after the review
- Writes a review artifact **only on confirmation**
- Hands off to `/review-fix` automatically when you pick "Apply fixes"

Designed for short, low-friction code changes where opening a full `/code-review` artifact is overkill.

**Flags**:

- `--parallel` — Fan out the REVIEW phase across 3 standalone `code-reviewer` sub-agents (correctness, security, quality) in parallel. Works in opencode, Cursor, and Codex bundles.

- `--team` — (Claude Code only) Same 3-reviewer fan-out as `--parallel`, dispatched as a coordinated agent team with `spawn coordinated subagents`, shared `the todo tracker`, per-reviewer task tracking, and coordinated shutdown before merge. Cursor and Codex bundles lack the team tools — use `--parallel` there instead.

- `--yes` — Skip the confirmation prompt and auto-confirm "Apply fixes". Useful for scripted flows. Mutually exclusive with `--save`.

- `--save` — Skip the confirmation prompt and auto-confirm "Save to file" (writes the artifact and exits; does not run `/review-fix`). Mutually exclusive with `--yes`.

- `--severity <CRITICAL|HIGH|MEDIUM|LOW>` — Minimum severity threshold forwarded to `/review-fix` during hand-off. Default: `HIGH`. Ignored on "Save to file" and "Discard".

- `--no-worktree` — Accepted as a **no-op**. Quick mode never creates a worktree.

`--parallel` and `--team` are **mutually exclusive** — pick one. Same for `--yes` and `--save`.

```
Usage: /quick-review [--parallel | --team] [--yes | --save] [--severity <level>] [--no-worktree]

Examples:
  /quick-review                               # inline review, prompt for confirmation
  /quick-review --parallel                    # 3 parallel sub-agent reviewers, prompt for confirmation
  /quick-review --team                        # 3-reviewer agent team (Claude Code only), prompt for confirmation
  /quick-review --yes                         # auto-confirm: write artifact + invoke /review-fix
  /quick-review --save                        # auto-confirm: write artifact + exit (run /review-fix later)
  /quick-review --yes --severity MEDIUM       # auto-confirm and lower the fix threshold
  /quick-review --parallel --yes              # parallel review + auto-apply fixes
```

The skill will:

1. `git diff --name-only HEAD` — abort if nothing is changed
2. REVIEW — single-pass, `--parallel`, or `--team` dispatch
3. Print findings **inline** in Review Artifact Format (no file written yet)
4. Ask: **Apply fixes** / **Save to file** / **Discard** (or act on `--yes` / `--save`)
5. On confirmation → write `docs/prps/reviews/quick-{timestamp}-review.md`; on **Apply fixes**, also invoke `/review-fix` inline

`/code-review --quick` delegates here. Use this command directly to access `--yes`, `--save`, and `--severity`.
