# Agent Team Dispatch — Canonical Lifecycle Reference

Used by `plan`, `prp-plan`, `prp-implement`, and `deep-research`
when the `--team` flag is passed. This file documents the universal spawn coordinated subagents → track the task → Agent →
the todo tracker → send follow-up instructions → end the coordinated run lifecycle. Individual skills own their teammate
roster and prompt templates; only the mechanism lives here.

---

## 1. Team Name Sanitization

Team names follow the pattern: `<skill-prefix>-<sanitized-context>`.

**Sanitization rules for the `<sanitized-context>` portion**:

1. Lowercase all characters.
2. Replace any character matching `[^a-z0-9-]` with `-`.
3. Collapse runs of `-` to a single `-`.
4. Trim leading and trailing `-`.
5. **Truncate to a maximum of 20 characters** for the `<sanitized-context>` portion
   (the prefix is excluded from this cap).

**Skill prefixes** (do not change):

| Skill                | Prefix  | Example                 |
| -------------------- | ------- | ----------------------- |
| `plan`           | `plan-` | `plan-add-rate-limit`   |
| `prp-plan`       | `prpp-` | `prpp-billing-webhooks` |
| `prp-implement`  | `prpi-` | `prpi-user-auth-flow`   |
| `implement-plan` | `impl-` | `impl-user-auth-flow`   |
| `deep-research`  | `drpr-` | `drpr-ai-deployment`    |

If the sanitized context would be empty (e.g., only symbols), fall back to
`untitled`.

---

## 2. Lifecycle (6 steps)

Every `--team` run MUST perform these steps in order. Deviation corrupts the
shared task list or leaves orphaned teammates.

### Step 1 — spawn coordinated subagents

```
spawn coordinated subagents: team_name="<prefix>-<sanitized-context>", description="<one-line purpose>"
```

The description should name the skill and the concrete goal (e.g., `"Multi-perspective
planning team for: add rate limiting"`). If `spawn coordinated subagents` fails, **abort the skill** with
a clear error. Do NOT silently fall back to a non-team mode — any teammates spawned
with a stale `team_name` will error, and orphaned teams make debugging harder.

### Step 2 — track the task (all tasks up front)

Register every subtask before spawning any teammates. Wire dependencies via
`addBlockedBy` so the shared task list reflects the full graph:

```
track the task: subject="<task-id>: <short description>", description="<full spec>"
update the todo tracker: taskId="<task-2-id>", addBlockedBy=["<task-1-id>"]
```

Up-front registration is important for multi-batch runs (e.g., `prp-implement`): it
preserves dependency state across batches and prevents the the todo tracker from resetting
when teammates from a completed batch are shut down.

For single-batch runs (e.g., `plan`, `prp-plan`), the task graph is flat — still
register all tasks before spawning.

### Step 3 — Agent spawn (single message, multiple calls)

**CRITICAL**: All teammates for a given batch MUST be spawned in **ONE message** with
**MULTIPLE `Agent` tool calls**. Sequential `Agent` calls across messages break the
parallel semantics.

Every `Agent` call MUST include both `team_name=` and `name=`:

```
Agent(
  team_name   = "<prefix>-<sanitized-context>",
  name        = "<teammate-name>",
  subagent_type = "<subagent-type>",
  description = "<one-line task title>",
  prompt      = "<full task prompt>"
)
```

The `name` must match the `track the task` `subject` prefix so the the todo tracker maps cleanly.

### Step 4 — the todo tracker monitoring

Use `the todo tracker` to confirm batch completion before advancing. Teammates mark their
tasks complete via `update the todo tracker`; the orchestrator reads status via `the todo tracker`. Do
NOT rely on agent return values alone — check the shared task state.

If a teammate messages the orchestrator with an issue, respond via `send follow-up instructions` with
guidance.

### Step 5 — send follow-up instructions (shutdown between batches)

Between batches — or at the end of a single-batch run before `end the coordinated run` — send a
shutdown request to every teammate of the completed batch:

```
send follow-up instructions(to="<teammate-name>", a shutdown request)
```

Wait for all shutdowns to complete before spawning the next batch (multi-batch runs)
or proceeding to Step 6 (single-batch runs).

### Step 6 — end the coordinated run

After the final batch completes (or if the skill aborts partway), clean up:

```
end the coordinated run
```

Always `end the coordinated run` — orphaned teams persist across skill invocations and pollute the
workspace.

---

## 3. Spawn Rule (non-negotiable)

- All teammates in a batch → ONE message → MULTIPLE `Agent` calls.
- Every `Agent` call includes `team_name=` + `name=`.
- No standalone sub-agent spawns mixed in.

If an implementation spawns an agent without `team_name`, it's a bug. Fix before
continuing.

---

## 4. Failure Policy

| Failure                        | Response                                                         |
| ------------------------------ | ---------------------------------------------------------------- |
| `spawn coordinated subagents` fails             | Abort skill; report error. Do NOT fall back silently.            |
| `track the task` fails             | `end the coordinated run`, then abort.                                        |
| Teammate returns error         | Record failure in the todo tracker; decide per skill (continue / abort). |
| Between-batch validation fails | Shutdown current batch, ask user (fix / sequential / abort).     |
| User aborts mid-run            | `send follow-up instructions(shutdown)` to active teammates, then `end the coordinated run`.  |

Never leave a team live after the skill exits.

---

## 5. Dry-Run Semantics

If the skill is invoked with both `--team` and `--dry-run` (where the skill
supports dry-run), print:

```
Team name:      <prefix>-<sanitized-context>
Teammates:      <count>
  - <name-1>   subagent_type=<type>   task=<short>
  - <name-2>   subagent_type=<type>   task=<short>
  ...
Batches:        <count>  (batch <n>: <comma-separated teammate names>)
Dependencies:   <edge-count>  (or "none" for flat graphs)
```

Do **not** call `spawn coordinated subagents`, `track the task`, `Agent`, `send follow-up instructions`, or `end the coordinated run` in
dry-run mode. The output above is the entire dry-run artifact.

---

## 6. Multi-Batch Runs (relevant to `prp-implement`)

For skills that process multiple batches against a single team:

1. `spawn coordinated subagents` once at the start.
2. `track the task` for **every task across all batches** up front, with `addBlockedBy`
   wiring dependencies.
3. For each batch in order:
   - Spawn teammates for the batch's tasks (single message, multiple `Agent` calls).
   - Wait for `the todo tracker` to show all batch tasks complete.
   - Run any between-batch validation the skill requires.
   - `send follow-up instructions(shutdown)` to all teammates of the completed batch.
4. `end the coordinated run` once at the end.

This is cheaper than recreating a team per batch and preserves dependency state
across batches. If validation fails between batches, the user may abort or switch
to a non-team mode — in both cases, `send follow-up instructions(shutdown)` + `end the coordinated run` first.

---

## 7. Worktree-aware team dispatch

When a skill combines `--team` with `--worktree`, each parallel teammate must operate
in its own child worktree so concurrent work doesn't corrupt a shared tree. Sequential
teammates share the parent worktree. The mechanism layers on top of §2's six-step
lifecycle and the parent/child model documented in
[worktree-strategy.md](./worktree-strategy.md).

### 7.1 Per-batch ordering

Exact ordering within ONE batch (critical for correctness):

1. `track the task` for all tasks in the batch (as in §2.2).
2. `setup-worktree.sh child <repo> <feature> <task-id>` for each parallel teammate —
   run **before** the `Agent` spawn message, in serial inside the orchestrator. (The
   orchestrator, not the teammates, creates the child worktrees.)
3. `Agent` spawn — one message, multiple `Agent` calls (per §2.3). Each call includes
   `team_name=`, `name=`, **and** a `Working directory: <child-path>` line in the
   prompt. On opencode, also pass `isolation: "worktree"` pointing at the
   pre-created child — this pairs with the `WorktreeCreate` hook.
4. `the todo tracker` monitor → `send follow-up instructions(shutdown)` to every teammate of the batch (per
   §2.4–2.5).
5. **After teammates shut down**: `merge-children.sh <repo> <feature> <task-ids,...>`
   → fan-in merges into the parent branch, removes child worktrees, deletes child
   branches.
6. On merge conflict (script exits 1 with `CONFLICT: <task-id> at <path>`): abort
   subsequent batches, inform the user, wait for manual resolution + explicit resume
   before proceeding.

The shutdown in step 4 **MUST** precede the merge in step 5 — children still open
when `merge-children.sh` runs will cause the merge to fail.

### 7.2 Sequential teammates

Teammates whose task has no parallel siblings (single task in a batch, or a
sequential chain) do **not** get a child worktree. They run in the parent worktree.
Do **not** pass `isolation: "worktree"` or a `Working directory:` line for them.

### 7.3 Dry-run interaction

`--dry-run` with `--team --worktree` adds a `Worktrees:` line to the existing dry-run
output format (§5):

```
Worktrees:   parent=~/.claude-worktrees/<repo>-<feature>/   children=<count>  (batch <n>: <child-paths>)
```

No `setup-worktree.sh` or `merge-children.sh` calls are made in dry-run mode.
