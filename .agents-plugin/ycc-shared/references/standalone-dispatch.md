# Standalone Dispatch — Task Tool Reference

Used by `prp-plan`, `deep-research`, `prp-implement`, `review-fix`,
`quick-fix`, `orchestrate`, `feature-research`, `parallel-plan`,
`shared-context`, `plan-workflow`, `clean`, and `git-workflow` for
**standalone** sub-agent fan-out (no shared team, no `--team` flag). This file documents
the `Task`-tool spawn/return contract. See [agent-team-dispatch.md](./agent-team-dispatch.md)
for the separate `Agent`+`team_name` lifecycle used by `--team`/Path C runs.

---

## 1. What `Task` Is

`Task` is the cross-target (Claude Code, Cursor, Codex, opencode) primitive for spawning
one or more sub-agents that run to completion and hand their result back to the caller in
the **same turn**, as the tool's return value. There is no roster, no shared task list, and
no `team_name` — each `Task` call is an independent, self-contained dispatch.

This is a fundamentally different mechanism from `Agent`+`team_name`:

|                 | `Task` (standalone)                        | `Agent` + `team_name` (Path C / `--team`)                               |
| --------------- | ------------------------------------------ | ----------------------------------------------------------------------- |
| Availability    | Claude Code, Cursor, Codex, opencode       | Claude Code only                                                        |
| Execution model | Blocking — caller waits for the result     | Async — spawns a background teammate                                    |
| Result delivery | Returned inline as the tool's return value | A "finished" notification only; output is **not** returned inline       |
| Coordination    | None — no shared task list                 | `TaskCreate`/`TaskList`/`SendMessage` against the shared team           |
| Lifecycle       | Fire, wait, read result, done              | `TeamCreate` → spawn → monitor → `SendMessage(shutdown)` → `TeamDelete` |

The "finished notification, no inline output" behavior of `Agent`+`team_name` is the root
cause of the bug this document exists to prevent: skills that dispatch standalone work via
`Agent` (instead of `Task`) and then try to read the sub-agent's findings inline get
nothing — the orchestrator goes idle waiting on output that was never returned to it.

---

## 2. Spawn Rule (non-negotiable)

All standalone sub-agents in a batch are spawned via **ONE message** with **MULTIPLE
`Task` tool calls**:

```
Task(subagent_type="<type>", description="<short title>", prompt="<full task prompt>")
Task(subagent_type="<type>", description="<short title>", prompt="<full task prompt>")
Task(subagent_type="<type>", description="<short title>", prompt="<full task prompt>")
```

- The call must **not** pass `name`, `team_name`, or `run_in_background`. Those
  parameters are exclusive to `Agent`+team dispatch (or async background execution) and
  have no meaning for a standalone `Task` call. Passing any of them — especially when the
  experimental `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` flag is enabled, which makes every
  session an implicit team — can silently convert what should be a blocking, inline
  `Task` dispatch into an async background teammate. That conversion is exactly the bug
  this document exists to prevent: it replaces the inline return with a "finished"
  notification, and orchestrators that expect the former end up sleep-looping (see §3-4).
- Do **not** call `TaskCreate`, `TaskList`, or `SendMessage` for standalone sub-agents —
  there is no shared task list backing a `Task` batch; those tools exist only for the
  `--team`/Agent-team lifecycle in `agent-team-dispatch.md`.
- Sequential `Task` calls across separate messages forfeit the parallel fan-out the
  pattern exists for — batch them into one message whenever the work is independent.

---

## 3. Blocking / Inline-Return Semantics

In the normal case, `Task` calls **block** the orchestrator until every sub-agent in the
batch returns, and each sub-agent's full report is delivered as that `Task` call's return
value, in the **same turn** the batch was dispatched. Read that return value directly —
this is the expected, common-case contract, and the vast majority of `Task` batches
resolve this way.

**Defensive fallback**: if the runtime ran the batch asynchronously (for example, a
runtime bug or a flag like `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS` reshaping the dispatch —
see §2) and the results are not yet in hand at the point where you would normally read
them, do **not** sleep-loop or poll waiting for them. Instead, **yield — end your turn**
(stop generating; do not call `sleep`, `echo`, or any other busywork tool "to wait") so
that any queued completion notification can flush. Resume merging results into the
skill's workflow once you are notified that the batch has completed.

The orchestrator must never:

- Poll for completion.
- `sleep` in a loop waiting for a `Task` call to "finish."
- Treat the absence of a notification, on its own, as proof that nothing returned — check
  the actual return value first; only fall back to yielding (above) if it is genuinely
  empty/missing at read time.

If a batch of `Task` calls returns inline, the work is done and every report is already in
hand — proceed directly to merging, no waiting required.

---

## 4. Hard Anti-Patterns

These mirror the Failure Policy intent of [agent-team-dispatch.md](./agent-team-dispatch.md)
§4, but for the standalone path. Each of the following is a bug, not a stylistic
preference:

- **Do NOT** dispatch standalone fan-out via `Agent`, or via `Task` with `name`,
  `team_name`, or `run_in_background` set (see §2). Any of these can produce a background
  teammate whose output is never returned inline — exactly the failure mode this document
  exists to prevent.
- **Do NOT** background a `Task` dispatch or otherwise detach from it.
- **Do NOT** `sleep`-loop or poll waiting for a `Task` call to complete. In the normal
  case `Task` blocks; the result is already available when the call returns.
- **Do NOT** keep the turn alive with `sleep`, `echo`, or any other busywork "waiting" for
  sub-agents to finish — including in the async-fallback case described in §3. In current
  Claude Code versions, a live turn blocks completion-notification delivery, so busywork
  "waiting" deadlocks the session until the user manually presses ESC. If there is nothing
  productive to do while waiting, end the turn.
- **Do NOT** rely on "finished" notifications as the primary way to retrieve standalone
  sub-agent output — the inline return value is. Only fall back to waiting on a
  notification (by yielding, per §3) if the inline return is genuinely empty/missing at
  read time.
- **Do NOT** call `SendMessage` or `TaskList` for standalone sub-agents. No shared task
  list exists for a `Task` batch; those tools only operate against an active
  `Agent`-team.
- **Do NOT** silently synthesize or fabricate findings when a sub-agent's inline return is
  empty or missing. Treat it as a failure and follow the Failure Policy in §6 — never
  paper over a missing result with invented content.

---

## 5. Disk-Artifact Backstop

Every content-producing sub-agent (researchers, reviewers, analyzers) should **also**
write its findings to a declared artifact path via `Write`, in addition to returning the
same content inline. This gives the orchestrator a backstop independent of the inline
return channel:

1. The orchestrator validates the inline return first.
2. If the inline return is empty or missing, re-read the backstop artifact from disk
   before treating the sub-agent as failed.
3. Only if **both** the inline return and the backstop artifact are empty/missing is the
   sub-agent considered to have failed (see §6).

For **code-writing** sub-agents (e.g. `implementor`, `review-fixer`), there is no
separate findings file — the "artifact" is the code changes already committed to disk,
plus a final `STATUS:` line in the inline return so the blocking `Task` result stays
parseable (e.g. `STATUS: Fixed` / `STATUS: Failed: <reason>`).

---

## 6. Failure Policy

| Failure                                                                               | Response                                                                                                                                   |
| ------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------ |
| Single sub-agent: empty/missing inline return **and** empty/missing backstop artifact | Record a gap. If non-critical to the overall task, continue without it. Otherwise, re-dispatch once with the same prompt before giving up. |
| Majority of a batch fails (empty/missing inline return **and** backstop artifact)     | Abort the skill run and report to the user, with guidance to retry. Do not attempt to synthesize a result from a majority-failed batch.    |
| Re-dispatch also fails                                                                | Treat as a true failure per the non-critical/abort branches above — do not re-dispatch more than once with an identical prompt.            |

Never silently drop a failed sub-agent's slot from downstream synthesis without recording
the gap — a quietly missing finding is worse than a reported one.

---

## 7. Cross-Target Portability

`Task` works identically on all four ycc deployment targets — Claude Code, Cursor, Codex,
and opencode. `Agent`+`team_name` does not: it is a Claude-Code-only primitive. Per the
`AGENTS:cursor` note in
[target-capability-matrix.md](./target-capability-matrix.md), Cursor (and, by the same
constraint, the Codex and opencode bundles) does not consume Claude Code agent-team
definitions directly — there is no team-tool surface (`TeamCreate`/`TaskCreate`/
`SendMessage`/`TeamDelete`) on those targets. Any skill that needs to run on all four
targets must use `Task` for its standalone fan-out path; `Agent`+`team_name` is reserved
for the Claude-Code-only `--team`/Path C path.
