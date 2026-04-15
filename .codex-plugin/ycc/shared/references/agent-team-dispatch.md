# Agent Team Dispatch — Canonical Lifecycle Reference

Used by `plan`, `prp-plan`, `prp-implement`, and `deep-research`
when the `--team` flag is passed. This file documents the universal create an agent group → record the task → Agent →
the task tracker → send follow-up instructions → close the agent group lifecycle. Individual skills own their teammate
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

| Skill            | Prefix  | Example                 |
| ---------------- | ------- | ----------------------- |
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

### Step 1 — create an agent group

```
create an agent group: name="<prefix>-<sanitized-context>", description="<one-line purpose>"
```

The description should name the skill and the concrete goal (e.g., `"Multi-perspective
planning team for: add rate limiting"`). If `create an agent group` fails, **abort the skill** with
a clear error. Do NOT silently fall back to a non-team mode — any teammates spawned
with a stale `team_name` will error, and orphaned teams make debugging harder.

### Step 2 — record the task (all tasks up front)

Register every subtask before spawning any teammates. Wire dependencies via
`addBlockedBy` so the shared task list reflects the full graph:

```
record the task: subject="<task-id>: <short description>", description="<full spec>"
update the task tracker: taskId="<task-2-id>", addBlockedBy=["<task-1-id>"]
```

Up-front registration is important for multi-batch runs (e.g., `prp-implement`): it
preserves dependency state across batches and prevents the the task tracker from resetting
when teammates from a completed batch are shut down.

For single-batch runs (e.g., `plan`, `prp-plan`), the task graph is flat — still
register all tasks before spawning.

### Step 3 — Agent spawn (single message, multiple calls)

**CRITICAL**: All teammates for a given batch MUST be spawned in **ONE message** with
**MULTIPLE `Agent` tool calls**. Sequential `Agent` calls across messages break the
parallel semantics.

Every `Agent` call MUST include both `name=` and `name=`:

```
Agent(
  team_name   = "<prefix>-<sanitized-context>",
  name        = "<teammate-name>",
  subagent_type = "<subagent-type>",
  description = "<one-line task title>",
  prompt      = "<full task prompt>"
)
```

The `name` must match the `record the task` `subject` prefix so the the task tracker maps cleanly.

### Step 4 — the task tracker monitoring

Use `the task tracker` to confirm batch completion before advancing. Teammates mark their
tasks complete via `update the task tracker`; the orchestrator reads status via `the task tracker`. Do
NOT rely on agent return values alone — check the shared task state.

If a teammate messages the orchestrator with an issue, respond via `send follow-up instructions` with
guidance.

### Step 5 — send follow-up instructions (shutdown between batches)

Between batches — or at the end of a single-batch run before `close the agent group` — send a
shutdown request to every teammate of the completed batch:

```
send follow-up instructions(to="<teammate-name>", a shutdown request)
```

Wait for all shutdowns to complete before spawning the next batch (multi-batch runs)
or proceeding to Step 6 (single-batch runs).

### Step 6 — close the agent group

After the final batch completes (or if the skill aborts partway), clean up:

```
close the agent group
```

Always `close the agent group` — orphaned teams persist across skill invocations and pollute the
workspace.

---

## 3. Spawn Rule (non-negotiable)

- All teammates in a batch → ONE message → MULTIPLE `Agent` calls.
- Every `Agent` call includes `name=` + `name=`.
- No standalone sub-agent spawns mixed in.

If an implementation spawns an agent without `team_name`, it's a bug. Fix before
continuing.

---

## 4. Failure Policy

| Failure                        | Response                                                                                   |
| ------------------------------ | ------------------------------------------------------------------------------------------ |
| `create an agent group` fails  | Abort skill; report error. Do NOT fall back silently.                                      |
| `record the task` fails        | `close the agent group`, then abort.                                                       |
| Teammate returns error         | Record failure in the task tracker; decide per skill (continue / abort).                   |
| Between-batch validation fails | Shutdown current batch, ask user (fix / sequential / abort).                               |
| User aborts mid-run            | `send follow-up instructions(shutdown)` to active teammates, then `close the agent group`. |

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

Do **not** call `create an agent group`, `record the task`, `Agent`, `send follow-up instructions`, or `close the agent group` in
dry-run mode. The output above is the entire dry-run artifact.

---

## 6. Multi-Batch Runs (relevant to `prp-implement`)

For skills that process multiple batches against a single team:

1. `create an agent group` once at the start.
2. `record the task` for **every task across all batches** up front, with `addBlockedBy`
   wiring dependencies.
3. For each batch in order:
   - Spawn teammates for the batch's tasks (single message, multiple `Agent` calls).
   - Wait for `the task tracker` to show all batch tasks complete.
   - Run any between-batch validation the skill requires.
   - `send follow-up instructions(shutdown)` to all teammates of the completed batch.
4. `close the agent group` once at the end.

This is cheaper than recreating a team per batch and preserves dependency state
across batches. If validation fails between batches, the user may abort or switch
to a non-team mode — in both cases, `send follow-up instructions(shutdown)` + `close the agent group` first.
