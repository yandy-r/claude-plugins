# Worktree Strategy — Canonical Reference

Used by `plan`, `prp-plan`, `parallel-plan`, `plan-workflow`,
`prp-implement`, `orchestrate`, and `implement-plan` when worktree
isolation is in effect. Also used by `code-review` and `review-fix` when
`--worktree` is set — with two twists: code-review checks out an existing PR head
branch into the parent (see `--base-ref` below) instead of branching from HEAD, and
review-fix keys its children by severity label (`critical`, `high`, `medium`, `low`)
instead of by parallel task ID. This file documents the parent/child worktree model,
naming scheme, plan annotation format, per-target dispatch matrix, fan-in merge
protocol, conflict policy, and cleanup convention. Individual skills own their own
`--worktree` flag plumbing and per-phase invocations; only the shared mechanism
lives here. See [agent-team-dispatch.md](./agent-team-dispatch.md) for the
complementary team lifecycle and how worktrees pair with teammate dispatch.

---

## 1. Parent / Child Model

Every worktree-enabled run uses at most two levels of worktrees.

### Parent worktree

| Property   | Value                                                  |
| ---------- | ------------------------------------------------------ |
| Path       | `~/.claude-worktrees/<repo>-<feature>/`                |
| Branch     | `feat/<feature>` (default) or `<base-ref>` (see below) |
| Created    | Once, before Batch 1 (via `setup-worktree.sh parent`)  |
| Lifetime   | Survives to end of run; used for the final PR          |
| Removed by | User (never auto-removed by the skill)                 |

The parent branch accumulates all work. After each parallel batch validates, child
branches are merged back here before the next batch begins.

#### Checking out an existing branch (`--base-ref`)

By default the parent worktree is placed on a new `feat/<feature>` branch created
from `HEAD`. Skills that need to isolate an **existing** branch (e.g.,
`code-review --worktree <N>` checking out a PR head) pass `--base-ref`:

```bash
# Default — new branch from HEAD
setup-worktree.sh parent <repo> <feature-slug>

# Check out an existing branch directly
setup-worktree.sh parent <repo> <feature-slug> --base-ref <branch>
```

When `--base-ref` is supplied:

- No new branch is created. The worktree is placed directly on `<branch>`.
- If `<branch>` does not resolve locally, the script runs
  `git fetch origin <branch>:<branch>` once and retries.
- The idempotency check expects the worktree to be on `<branch>`, not on
  `feat/<feature-slug>`.
- The worktree cannot coexist with the same branch already checked out in the
  main repo. Switch away from `<branch>` in the main repo first, or pick a
  different base ref.

All fan-in merge behavior (children branch from the parent branch) is unchanged —
children merge into `<branch>` instead of `feat/<feature-slug>`.

### Child worktrees (parallel tasks only)

| Property   | Value                                                           |
| ---------- | --------------------------------------------------------------- |
| Path       | `~/.claude-worktrees/<repo>-<feature>-<task-id>/`               |
| Branch     | `feat/<feature>-<task-id>`                                      |
| Created    | Just-in-time before each parallel batch (one per parallel task) |
| Lifetime   | Ephemeral — removed after the batch validates and merges back   |
| Removed by | `merge-children.sh` (automatic fan-in, post-validation)         |

One child worktree is created per parallel task in a batch. Children always branch
from `feat/<feature>` (the parent branch) at the time of creation, so each task
starts from a consistent shared baseline.

### Sequential tasks

Sequential tasks do **not** get child worktrees. They run directly in the parent
worktree at `~/.claude-worktrees/<repo>-<feature>/`. No child setup or merge-back
is needed for sequential tasks.

### Task ID convention

Task IDs use hyphens in worktree paths and branch names. The `.` separator used in
plan files (e.g., `1.1`, `2.3`) is replaced with `-` because `.` is ambiguous in
filesystem paths and git refs.

| Plan task ID | Worktree path suffix | Branch name suffix |
| ------------ | -------------------- | ------------------ |
| `1.1`        | `-1-1/`              | `-1-1`             |
| `2.3`        | `-2-3/`              | `-2-3`             |
| `10.4`       | `-10-4/`             | `-10-4`            |

---

## 2. Plan Annotation Format

Planners that support `--worktree` emit two kinds of annotation into the plan
artifact. Implementors parse these annotations automatically — no flag is required
when a plan already contains them.

### Top-level `## Worktree Setup` section

Placed at the top of the plan, after frontmatter and before the first batch or step:

```markdown
## Worktree Setup

- **Parent**: ~/.claude-worktrees/<repo>-<feature>/ (branch: feat/<feature>)
- **Children** (per parallel task; merged back at end of each batch):
  - Task 1.1 → ~/.claude-worktrees/<repo>-<feature>-1-1/ (branch: feat/<feature>-1-1)
  - Task 1.2 → ~/.claude-worktrees/<repo>-<feature>-1-2/ (branch: feat/<feature>-1-2)
```

### Per-parallel-task inline annotation

Placed on its own line inside the task block, immediately after the task header:

```markdown
- **Worktree**: ~/.claude-worktrees/<repo>-<feature>-<task-id>/ (branch: feat/<feature>-<task-id>)
```

### Sequential tasks

Sequential tasks carry **no** worktree annotation. Their absence of a
`**Worktree**:` line is the signal that the task runs in the parent worktree.

### Severity-keyed children (`review-fix` variant)

`code-review --worktree` and `review-fix --worktree` use the same
`## Worktree Setup` section, but children are labelled by **severity** instead of
by task ID. Each severity label (`critical`, `high`, `medium`, `low`) functions
as the `<task-id>` arg to `setup-worktree.sh child` and `merge-children.sh` —
they are shell-safe, unique, and already lowercase.

Example (emitted by `/code-review --worktree 42`, consumed by
`/review-fix --worktree 42`):

```markdown
## Worktree Setup

- **Parent**: ~/.claude-worktrees/myrepo-pr-42/ (branch: feature-x)
- **Children** (per severity; created by /review-fix --worktree):
  - CRITICAL → ~/.claude-worktrees/myrepo-pr-42-critical/ (branch: feat/pr-42-critical)
  - HIGH → ~/.claude-worktrees/myrepo-pr-42-high/ (branch: feat/pr-42-high)
```

Only severity levels that have Open findings are emitted. The parent branch is
the PR's head branch (via `--base-ref`), not `feat/pr-<N>`.

---

## 3. Lifecycle (per parallel batch)

The following 5-step loop runs once per parallel batch. Parent setup is one-time,
executed before Batch 1.

**One-time setup (before Batch 1)**

```bash
#!/usr/bin/env bash
set -euo pipefail
setup-worktree.sh parent <repo> <feature-slug>
```

**Per-batch loop**

### Step 1 — Create child worktrees (before spawn)

For each parallel task in the batch, call:

```bash
setup-worktree.sh child <repo> <feature-slug> <task-id>
```

Children must exist before agents are spawned. The calling skill creates all
children in a single message's tool calls — no race conditions because child paths
are task-ID-scoped and the orchestrator serializes creation.

### Step 2 — Spawn agents

Each parallel agent receives its child worktree path as context:

- **Claude Code**: prefer `Agent(isolation: "worktree")` with the pre-created child
  path; the `WorktreeCreate` hook redirects the path to `~/.claude-worktrees/`.
  Fall back to Bash-created child + `Working directory: <path>` in the agent prompt
  if the hook is not registered.
- **Codex / opencode**: always Bash-created child + `Working directory: <path>`
  embedded in the agent prompt. No tool-level isolation is available.
- **Cursor**: emit `git worktree add` commands as part of the plan output for the
  user to run manually. Do not auto-create.

The agent must treat the `Working directory:` path as its repo root for every
Read / Write / Edit / Bash call.

### Step 3 — Validate batch outputs

Run whatever between-batch validation the skill requires (tests, lint, validators).
Do not proceed to Step 4 until all tasks in the batch are confirmed complete and
valid.

### Step 4 — Fan-in merge (after validation)

```bash
merge-children.sh <repo> <feature-slug> <task-id-1>,<task-id-2>,...
```

For each child: merges `feat/<feature>-<task-id>` into the parent branch with
`git merge --no-ff`, removes the child worktree, and deletes the child branch.
All children in the batch are processed before the next batch begins.

### Step 5 — Conflict handling

If `merge-children.sh` encounters a conflict during any child merge, it:

1. Runs `git merge --abort` to leave the parent branch clean.
2. Prints `CONFLICT: <task-id> at <path>` to stderr.
3. Exits with code 1.

The calling skill must **pause**, surface the conflict message to the user, and
**wait for manual resolution** (`git merge --abort` or manual resolve + commit in
the parent worktree) before starting the next batch. Never silently skip a failed
child or continue to the next batch with a dirty parent branch.

---

## 4. Per-Target Dispatch Matrix

| Target      | Primary mechanism                                      | Fallback                |
| ----------- | ------------------------------------------------------ | ----------------------- |
| Claude Code | `Agent(isolation: "worktree")` + `WorktreeCreate` hook | Bash `git worktree add` |
| Codex       | Bash `git worktree add` via prompt                     | same                    |
| opencode    | Bash `git worktree add` via prompt                     | same                    |
| Cursor      | Docs-only (emit commands; no auto-create)              | User runs manually      |

See [target-capability-matrix.md](./target-capability-matrix.md) for the full
per-target feature table, including the `worktree` row.

---

## 5. Conflict Policy

`merge-children.sh` aborts on first conflict. It does not attempt to auto-resolve
or skip any child — partial fan-in leaves the parent in an inconsistent state.

**Abort protocol**:

1. `git merge --abort` — restores the parent branch to pre-merge HEAD.
2. Emit `CONFLICT: <task-id> at <path>` to stderr (one line per conflicting child).
3. Exit 1.

**Skill responsibility after abort**:

- Show the user the `CONFLICT:` line(s).
- Display the conflicting file(s) from the child branch for manual review.
- Wait for the user to either:
  - Resolve the conflict manually in the parent worktree and run
    `merge-children.sh` again for the remaining children, or
  - Abandon the batch and decide how to proceed.
- Never advance to the next batch until the fan-in is clean.

---

## 6. End-of-Run Cleanup

The parent worktree survives at `~/.claude-worktrees/<repo>-<feature>/` after the
run completes. Skills never auto-remove it.

The end-of-run report (produced by `list-worktrees.sh`) includes:

- The surviving parent worktree path and its branch.
- The `git worktree remove` command for manual cleanup:

  ```bash
  git worktree remove ~/.claude-worktrees/<repo>-<feature>/
  git branch -d feat/<feature>
  ```

- A hint to push the parent branch and open a PR before removing the worktree.

All child worktrees and child branches should be gone by end of run (removed by
`merge-children.sh` after each batch). If any children remain (e.g., the run was
aborted mid-batch), `list-worktrees.sh` lists them with their own
`git worktree remove` commands.

---

## 7. Claude Code `WorktreeCreate` Hook Integration

When a skill dispatches an agent with `Agent(isolation: "worktree")`, the Claude
Code harness would normally create the worktree inside the repo at
`<repo>/.cursor/worktrees/`. The `WorktreeCreate` hook registered in
`ycc/settings/settings.json` intercepts this and redirects the path to
`~/.claude-worktrees/<repo>-<branch>/`, keeping worktrees outside every repo and
preventing pollution of the working tree. The hook body lives at
`ycc/settings/hooks/worktree-create.sh`. The full worktree placement policy is
documented in `ycc/settings/rules/CLAUDE.md:207–224`.
