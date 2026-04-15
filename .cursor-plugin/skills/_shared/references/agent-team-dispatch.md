# Agent Team Dispatch — Canonical Lifecycle Reference

Used by `plan`, `prp-plan`, `prp-implement`, and `deep-research`
when the `--team` flag is passed. This file documents the universal TeamCreate → TaskCreate → Agent →
TaskList → SendMessage → TeamDelete lifecycle. Individual skills own their teammate
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

| Skill           | Prefix  | Example                 |
| --------------- | ------- | ----------------------- |
| `plan`          | `plan-` | `plan-add-rate-limit`   |
| `prp-plan`      | `prpp-` | `prpp-billing-webhooks` |
| `prp-implement` | `prpi-` | `prpi-user-auth-flow`   |
| `deep-research` | `drpr-` | `drpr-ai-deployment`    |

If the sanitized context would be empty (e.g., only symbols), fall back to
`untitled`.

---

## 2. Lifecycle (6 steps)

Every `--team` run MUST perform these steps in order. Deviation corrupts the
shared task list or leaves orphaned teammates.

### Step 1 — TeamCreate

```
TeamCreate: team_name="<prefix>-<sanitized-context>", description="<one-line purpose>"
```

The description should name the skill and the concrete goal (e.g., `"Multi-perspective
planning team for: add rate limiting"`). If `TeamCreate` fails, **abort the skill** with
a clear error. Do NOT silently fall back to a non-team mode — any teammates spawned
with a stale `team_name` will error, and orphaned teams make debugging harder.

### Step 2 — TaskCreate (all tasks up front)

Register every subtask before spawning any teammates. Wire dependencies via
`addBlockedBy` so the shared task list reflects the full graph:

```
TaskCreate: subject="<task-id>: <short description>", description="<full spec>"
TaskUpdate: taskId="<task-2-id>", addBlockedBy=["<task-1-id>"]
```

Up-front registration is important for multi-batch runs (e.g., `prp-implement`): it
preserves dependency state across batches and prevents the TaskList from resetting
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

The `name` must match the `TaskCreate` `subject` prefix so the TaskList maps cleanly.

### Step 4 — TaskList monitoring

Use `TaskList` to confirm batch completion before advancing. Teammates mark their
tasks complete via `TaskUpdate`; the orchestrator reads status via `TaskList`. Do
NOT rely on agent return values alone — check the shared task state.

If a teammate messages the orchestrator with an issue, respond via `SendMessage` with
guidance.

### Step 5 — SendMessage (shutdown between batches)

Between batches — or at the end of a single-batch run before `TeamDelete` — send a
shutdown request to every teammate of the completed batch:

```
SendMessage(to="<teammate-name>", message={type: "shutdown_request"})
```

Wait for all shutdowns to complete before spawning the next batch (multi-batch runs)
or proceeding to Step 6 (single-batch runs).

### Step 6 — TeamDelete

After the final batch completes (or if the skill aborts partway), clean up:

```
TeamDelete
```

Always `TeamDelete` — orphaned teams persist across skill invocations and pollute the
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
| `TeamCreate` fails             | Abort skill; report error. Do NOT fall back silently.            |
| `TaskCreate` fails             | `TeamDelete`, then abort.                                        |
| Teammate returns error         | Record failure in TaskList; decide per skill (continue / abort). |
| Between-batch validation fails | Shutdown current batch, ask user (fix / sequential / abort).     |
| User aborts mid-run            | `SendMessage(shutdown)` to active teammates, then `TeamDelete`.  |

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

Do **not** call `TeamCreate`, `TaskCreate`, `Agent`, `SendMessage`, or `TeamDelete` in
dry-run mode. The output above is the entire dry-run artifact.

---

## 6. Multi-Batch Runs (relevant to `prp-implement`)

For skills that process multiple batches against a single team:

1. `TeamCreate` once at the start.
2. `TaskCreate` for **every task across all batches** up front, with `addBlockedBy`
   wiring dependencies.
3. For each batch in order:
   - Spawn teammates for the batch's tasks (single message, multiple `Agent` calls).
   - Wait for `TaskList` to show all batch tasks complete.
   - Run any between-batch validation the skill requires.
   - `SendMessage(shutdown)` to all teammates of the completed batch.
4. `TeamDelete` once at the end.

This is cheaper than recreating a team per batch and preserves dependency state
across batches. If validation fails between batches, the user may abort or switch
to a non-team mode — in both cases, `SendMessage(shutdown)` + `TeamDelete` first.
