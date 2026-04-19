---
name: plan
description: Lightweight conversational planner that dispatches the planner agent
  (or a multi-perspective agent team) to produce a specific, phased implementation
  plan with file paths, dependencies, risks, and a testing strategy — then WAITS for
  explicit user confirmation before any code is written. Pass `--parallel` to instruct
  the planner to shape its output for parallel execution (Batches summary section,
  hierarchical step IDs, explicit Depends on annotations). Pass `--team` to spawn
  a 3-persona team (architect / risk-analyst / test-strategist) and merge their outputs
  into a richer plan. Flags are independent and combinable. Use for quick planning
  on a new feature, architectural change, or complex refactor when you do NOT need
  the heavier parallel-agent plan-workflow or the PRD-driven prp-plan. Use when the
  user asks to "plan this", "outline an approach", "break this down before I code",
  "parallel plan", "multi-perspective plan", or says "/plan".
---

# Plan Skill

Create a comprehensive implementation plan before writing any code. This is the lightweight conversational planner. For heavier planning tracks, see the comparison table at the bottom.

**Core rule**: You will **NOT** write any code until the user explicitly confirms the plan with "yes", "proceed", "approved", or similar affirmative.

---

## What This Skill Does

1. **Parse flags and the request** — Extract `--parallel`, `--team`, `--dry-run`, then read the user input and any referenced files
2. **Dispatch planner(s)** — Either dispatch a single `planner` (default) or deploy a 3-persona agent team (`--team`). In parallel mode, augment the prompt(s) with output-shape directives
3. **Merge and relay the plan** — For the single-agent path, relay verbatim. For the team path, merge the 3 teammate outputs into one unified plan
4. **Wait for confirmation** — MUST receive explicit user approval before proceeding

## Flags

| Flag         | Effect                                                                                                                                                                                                                                                                                                                                                                                                                                            |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--parallel` | Instruct the planner(s) to emit a parallel-capable plan: a `Batches` summary section at the top, hierarchical step IDs (`1.1`, `1.2`, `2.1`), and explicit `Depends on [...]` annotations on every step. Enables in-conversation parallel implementation via `implementor` agents, or file-based handoff to `/prp-implement --parallel`.                                                                                                  |
| `--team`     | Dispatch a 3-persona planning team (architect / risk-analyst / test-strategist) under a shared `spawn coordinated subagents`/`the todo tracker` with coordinated shutdown. Produces a richer plan by merging structural, risk, and testing perspectives. Heavier than the default single-agent path.                                                                                                                                                                       |
| `--dry-run`  | Only valid with `--team`. Prints the team name and teammate roster, then exits without spawning any teammates.                                                                                                                                                                                                                                                                                                                                    |
| `--worktree` | Instruct the planner to emit worktree annotations in the plan: a top-level `## Worktree Setup` block (parent + per-parallel-task children) and a `**Worktree**:` field on every parallel task. Follows `.opencode-plugin/skills/_shared/references/worktree-strategy.md`. The plan's implementor (e.g., `/prp-implement --worktree`) consumes these annotations to run each parallel task in its own git worktree with auto fan-in merge after each batch. |

**Flag interaction**:

- `--parallel` and `--team` are **independent and combinable**. `--parallel` shapes the plan's _output format_; `--team` switches the _dispatch mechanism_. Pass both for a multi-perspective plan formatted for parallel execution.
- `--dry-run` requires `--team` (the single-agent path has nothing to dry-run).
- `--worktree` combines freely with `--parallel` and `--team`. When combined with `--parallel`, every parallel task gets a child worktree annotation. When combined with `--team`, teammates dispatch into child worktrees per §7 of `agent-team-dispatch.md`.

**Note**: `--parallel` on `/plan` shapes the _output_, not the research phase. For research fan-out on larger features, use `/prp-plan --parallel` (sub-agent fan-out) or `/prp-plan --team` (Claude Code only; shared-task-list coordination).

## When to Use

Use this skill when:

- Starting a new feature
- Making significant architectural changes
- Working on complex refactoring
- Multiple files/components will be affected
- Requirements are unclear or ambiguous

---

## Process

### Step 1 — Parse flags and the user's request

**Flag parsing**: Extract `--parallel`, `--team`, `--dry-run`, and `--worktree` from `$ARGUMENTS` before processing. Strip them out and set `PARALLEL_MODE=true|false`, `AGENT_TEAM_MODE=true|false`, `DRY_RUN=true|false`, `WORKTREE_MODE=true|false`. The remaining text is the user's request.

**Validation**:

- If `DRY_RUN=true` and `AGENT_TEAM_MODE=false` → abort with: `--dry-run requires --team (no-op for the single-agent path).`

Read the stripped `$ARGUMENTS`. If it references a file path, read that file for context. If the request is ambiguous, ask a single focused clarifying question **before** dispatching.

### Step 2 — Dispatch

Choose dispatch path based on `AGENT_TEAM_MODE`:

- **`AGENT_TEAM_MODE=false`** (default) → **Path A**: single `planner` agent.
- **`AGENT_TEAM_MODE=true`** → **Path B**: 3-persona planning team.

---

### Path A — Single-agent dispatch (default)

Mention `@planner` or invoke it via the built-in `task` tool. In the prompt, include:

- The user's original request (verbatim)
- Any file paths or context they referenced
- A note that the agent should follow its Plan Format and end with `**WAITING FOR CONFIRMATION**: Proceed with this plan? (yes / no / modify)`
- **If `PARALLEL_MODE=true`**: append the parallel output directives (see below)

#### Sequential prompt (`PARALLEL_MODE=false` — default)

```
The user asked: "<user's request>"

Related context they pointed to: <files, URLs, or "none">

Produce a full implementation plan following your Plan Format. Use the
Read/Grep/Glob tools to analyze the codebase and include concrete file
paths. End with your standard confirmation prompt.
```

#### Parallel prompt (`PARALLEL_MODE=true`)

Append these directives to the sequential prompt:

```
PARALLEL OUTPUT MODE:

In addition to your standard Plan Format, shape the output for parallel
execution:

1. **Use hierarchical step IDs** — Number steps as `1.1`, `1.2`, `2.1`,
   `2.2`, etc. where the first digit is the batch and the second is the
   task within the batch.

2. **Populate the Dependencies field on every step** — Use the hierarchical
   IDs (e.g., `Depends on [1.1, 1.2]` or `Depends on [none]`). Never leave
   the field as "None / Requires step X" — always use the explicit format.

3. **Add a `## Batches` section immediately after `## Architecture Changes`
   and before `## Implementation Steps`**. Format:

   ## Batches

   Steps grouped by dependency for parallel execution. Steps within the
   same batch run concurrently; batches run in order.

   | Batch | Steps         | Depends On | Parallel Width |
   | ----- | ------------- | ---------- | -------------- |
   | B1    | 1.1, 1.2, 1.3 | —          | 3              |
   | B2    | 2.1           | B1         | 1              |
   | B3    | 3.1, 3.2      | B2         | 2              |

   - **Total steps**: N
   - **Total batches**: M
   - **Max parallel width**: X

4. **Batch construction rules**:
   - Steps with no dependencies go in Batch 1
   - A step joins the earliest batch where all its dependencies are in
     prior batches
   - Steps modifying the same file MUST be in different batches (no
     concurrent writes)
   - Cross-cutting changes (shared types, global config) get a dedicated
     early batch so downstream steps can depend on them
   - Prefer wide-shallow graphs (many independent steps per batch) over
     narrow-deep chains — maximize parallel width

5. **Still end with** `**WAITING FOR CONFIRMATION**: Proceed with this
   plan? (yes / no / modify)`
```

#### Worktree prompt (`WORKTREE_MODE=true`)

Append these directives to the prompt:

```
WORKTREE MODE:

The plan consumer will run each parallel task in its own git worktree.
In your emitted plan:

1. Add a top-level `## Worktree Setup` section BEFORE the Batches summary:
   - `**Parent**: ~/.claude-worktrees/<repo>-<feature-slug>/   (branch: feat/<feature-slug>)`
   - A nested `**Children**` list with one entry per parallel task:
     `Task <id> → ~/.claude-worktrees/<repo>-<feature-slug>-<task-id>/   (branch: feat/<feature-slug>-<task-id>)`
     (Hyphenate dots in task IDs: `1.1` → `1-1`.)

2. On every parallel task step, add a `- **Worktree**:` field matching the
   child path.

3. Sequential tasks carry NO worktree annotation — they run in the parent.

See `.opencode-plugin/skills/_shared/references/worktree-strategy.md` for the canonical format.
```

---

### Path B — Agent-team dispatch (`AGENT_TEAM_MODE=true`)

> **MANDATORY — AGENT TEAMS REQUIRED**
>
> In Path B you MUST use the agent-team lifecycle. Do NOT mix standalone sub-agents with
> team dispatch. Every `Agent` call below MUST include `team_name=` AND `name=`.
>
> 1. `spawn coordinated subagents` FIRST — before any agent spawn
> 2. `track the task` — register all 3 subtasks in the shared task list
> 3. `Agent` with `team_name=` — one message, three calls
> 4. `the todo tracker` — wait for all teammates to mark complete
> 5. `send follow-up instructions({type:"shutdown_request"})` — shut down all teammates
> 6. `end the coordinated run` — clean up
>
> If `spawn coordinated subagents` fails, abort the skill with a clear error. Do NOT silently fall back
> to Path A. Refer to `~/.config/opencode/shared/references/agent-team-dispatch.md`
> for the full lifecycle contract.

#### B.1 Build the team name

Sanitize the user's request to produce `<sanitized-request>`:

- Lowercase; replace non-`[a-z0-9-]` with `-`; collapse runs of `-`; trim; truncate to
  **20 characters** max. Fall back to `untitled` if empty.

Team name: `plan-<sanitized-request>`.

#### B.2 Dry-run gate (if `DRY_RUN=true`)

Print:

```
Team name:   plan-<sanitized-request>
Teammates:   3
  - architect       subagent_type=planner                    task=Structural plan, phases, file layout, dependencies
  - risk-analyst    subagent_type=codebase-research-analyst  task=Risks, edge cases, rollback, migration concerns
  - test-strategist subagent_type=test-strategy-planner      task=Testing strategy, validation commands, acceptance criteria
Batches:     1  (batch 1: architect, risk-analyst, test-strategist)
Dependencies: none  (flat graph)
```

Do **not** call `spawn coordinated subagents` or any team/task/agent tools. Exit the skill.

#### B.3 Create the team

```
spawn coordinated subagents: team_name="plan-<sanitized-request>", description="Multi-perspective planning team for: <user request>"
```

On failure, abort.

#### B.4 Register subtasks

Create 3 tasks in the shared task list (flat graph — no dependencies):

```
track the task: subject="architect: structural plan for <user request>", description="..."
track the task: subject="risk-analyst: risks and edge cases for <user request>", description="..."
track the task: subject="test-strategist: testing strategy for <user request>", description="..."
```

#### B.5 Spawn the 3 teammates (single message, three Agent calls)

| Teammate name     | `subagent_type`                 | Role focus                                                 |
| ----------------- | ------------------------------- | ---------------------------------------------------------- |
| `architect`       | `planner`                   | Structural plan, phases, file layout, dependencies         |
| `risk-analyst`    | `codebase-research-analyst` | Risks, edge cases, rollback, migration concerns            |
| `test-strategist` | `test-strategy-planner`     | Testing strategy, validation commands, acceptance criteria |

Spawn all three in **ONE message** with **THREE `Agent` tool calls**, each with
`team_name="plan-<sanitized-request>"` and the role-specific `name` above.

Each teammate's prompt MUST include:

- The user's original request (verbatim)
- Any file paths or context they referenced
- The teammate's role focus (from the table) — make it clear what slice of the plan
  this teammate owns
- Instruction to coordinate via `send follow-up instructions` if they discover work overlapping another
  teammate's scope (reference the teammate roster so they know who is working alongside
  them)
- If `PARALLEL_MODE=true`: append the same parallel output directives from Path A
  (section "Parallel prompt") — each teammate should structure its own slice with
  hierarchical step IDs and `Depends on` annotations
- If `WORKTREE_MODE=true`: append the same worktree directives from Path A
  (section "Worktree prompt") — each teammate should annotate its parallel tasks
  with child worktree paths per §7 of `agent-team-dispatch.md`

#### B.6 Monitor and collect results

Use `the todo tracker` to confirm all 3 tasks are `completed` before merging. If any teammate
errors, record the failure in `the todo tracker` and decide per severity:

- `architect` failure → critical; abort with error, shut down remaining teammates, `end the coordinated run`.
- `risk-analyst` or `test-strategist` failure → record "partial plan — {role} did not
  complete" and proceed with a 2-persona merge, noting the gap in the relayed plan.

#### B.7 Merge outputs

Synthesize the 3 teammate outputs into a single unified plan following the standard
`planner` Plan Format. Merging rules:

- **Overview / Summary**: use `architect`'s framing.
- **Architecture Changes / Implementation Steps**: primarily `architect`; fold in
  `risk-analyst`'s findings as per-step risk callouts or a dedicated `## Risks &
Mitigations` section.
- **Testing Strategy / Success Criteria**: use `test-strategist`'s content verbatim.
- **Batches section** (if `PARALLEL_MODE=true`): use `architect`'s numbering; re-index
  if `risk-analyst` or `test-strategist` added follow-on steps.
- End with the standard confirmation prompt: `**WAITING FOR CONFIRMATION**: Proceed
with this plan? (yes / no / modify)`

#### B.8 Shutdown and cleanup

After merging (success or partial):

```
send follow-up instructions(to="architect",       message={type:"shutdown_request"})
send follow-up instructions(to="risk-analyst",    message={type:"shutdown_request"})
send follow-up instructions(to="test-strategist", message={type:"shutdown_request"})
end the coordinated run
```

Always `end the coordinated run` — even on abort or partial failure.

---

### Step 2.5 — Validate the plan before relaying

After the `planner` agent returns its plan, perform these quick checks BEFORE presenting it to the user. Use only the tools already available to this skill.

#### Check 1: Structure completeness

Scan the agent's response for these sections. If any **required** section is missing, re-dispatch the planner with a note to include the missing section(s).

**Required** (re-dispatch if missing):

- `## Overview` or `## Summary`
- `## Implementation Steps` or `## Step-by-Step Tasks`
- `## Testing Strategy`
- `**WAITING FOR CONFIRMATION**`

**Expected** (append a note to the plan if missing, but do NOT re-dispatch):

- `## Architecture Changes` or `## Requirements`
- `## Risks` or `## Risks & Mitigations`
- `## Success Criteria`

#### Check 2: File path spot-check

Extract up to 10 file paths from the plan (backtick-quoted paths or paths after `File:` annotations). For each, use Glob or `Bash: test -f "<path>"` to check existence.

- If **all paths exist**: clean pass, append nothing.
- If **>30% of checked paths are missing**: append a validation note before relaying:

  > **Validation Note**: {N} of {M} file paths in this plan could not be found in the current codebase. This may indicate renamed files, planned new files, or stale references. Review the paths in the Implementation Steps before confirming.

- If **a few paths are missing** (≤30%): append a lighter note listing only the missing paths.

#### Check 3: Parallel mode integrity (`PARALLEL_MODE=true` only)

If the plan was requested with `--parallel`, verify:

- A `## Batches` section exists in the response
- At least one `Depends on` annotation exists
- Step IDs use hierarchical format (N.N)

If any are missing, re-dispatch the planner (or `architect` teammate, if in Path B — but only _after_ `end the coordinated run` has run; do not try to re-spawn inside a torn-down team) with a directive to add the missing parallel annotations.

#### Check 4: Agent-team merge integrity (`AGENT_TEAM_MODE=true` only)

After Path B merge, verify the unified plan reflects all three perspectives:

- `architect` slice: `## Implementation Steps` (or equivalent) is present and non-empty
- `risk-analyst` slice: a `## Risks` / `## Risks & Mitigations` section OR per-step risk callouts are present
- `test-strategist` slice: `## Testing Strategy` is present and non-empty

If the merge dropped a slice (e.g., because a teammate errored), append a visible note:

> **Validation Note**: The {role} perspective could not be included in this plan (teammate error). Review the plan for gaps in {area} before confirming.

---

### Step 3 — Relay the plan

Present the agent's plan to the user verbatim, including any validation notes appended in Step 2.5. Do not summarize, do not shorten, do not add your own commentary above it.

### Step 4 — WAIT

Do not touch any code until the user responds.

Valid user responses:

- **"yes" / "proceed" / "approved"** → proceed to implement
- **"modify: ..."** → re-dispatch the planner (Path A) or re-run Path B (new spawn coordinated subagents — the previous team was deleted in B.8) with the modification request and the previous plan as context
- **"different approach: ..."** → discard and re-dispatch Path A or re-run Path B with the new direction
- **"skip phase N and do phase M first"** → re-dispatch with the reorder request
- **"no"** → stop, do not implement

**Team-mode re-dispatch note**: Path B's team is `end the coordinated run`d in Step B.8 _before_ the user sees the plan. Any re-dispatch from this step creates a **new** team (same name is fine — the old one no longer exists) with a fresh set of teammates. Do not attempt to send messages to teammates from the prior team.

---

## Important Notes

**CRITICAL**: This skill will NOT write any code until the user explicitly confirms.

Do not summarize, do not touch files, do not run commands beyond read-only analysis. Wait.

If the user's instructions are unclear after the planner produces a draft, ask a focused clarifying question rather than guessing, then re-dispatch the planner with the clarification.

The `planner` agent owns the plan format, worked examples, sizing/phasing guidance, and red-flag checks. This skill is an orchestration layer — it decides _when_ to plan and _what_ to do with the plan, not _how_ a plan should be structured.

For Path B's team lifecycle contract (sanitization, shutdown sequence, failure policy), refer to:

```
~/.config/opencode/shared/references/agent-team-dispatch.md
```

---

## Integration with ycc

After planning, depending on what the user approves:

- Use `/prp-implement` if they want rigorous per-task validation loops (requires a PRP-format plan file — consider running `/prp-plan` first if you want that workflow)
- Use `/implement-plan` if the work was structured via `/parallel-plan`
- Use `/code-review` to review completed implementation
- Use `/git-workflow` or `/prp-commit` to commit

### Executing a Parallel Plan

If the plan was produced with `--parallel` (has a `Batches` section and `Depends on` annotations), after the user confirms you have two options for parallel execution:

**Option 1 — In-conversation parallel execution (lightweight)**

Process batches sequentially. Within each batch, dispatch one `implementor` agent per step in a SINGLE message with MULTIPLE `Agent` tool calls. Between batches, run the project's type-check and unit-test commands. On failure, stop and ask the user how to proceed.

This keeps everything in the current conversation — no file artifact needed.

**Option 2 — Save to file and hand off (rigorous)**

Write the plan to `docs/prps/plans/{name}.plan.md` (adapting it to the PRP plan template if needed: add `Patterns to Mirror`, `Files to Change`, `Validation Commands`, etc.), then run `/prp-implement --parallel docs/prps/plans/{name}.plan.md` for the full 5-level validation pipeline.

Use Option 1 for small features and quick iterations. Use Option 2 when the user wants an implementation report, per-task validation logs, and the plan archived for audit.

---

## Comparison with other ycc planning tracks

| Track                  | When to use                                                                                                                                             |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/plan` (this one) | Quick conversational plan via `planner` agent. No artifact file. Add `--parallel` to shape the output for parallel execution (no research fan-out). |
| `/prp-plan`        | Artifact-producing plan with codebase pattern extraction. Single-pass. Add `--parallel` for 3-researcher fan-out + batched plan.                        |
| `/prp-prd`         | Interactive PRD first, then prp-plan. Problem-first hypothesis workflow.                                                                                |
| `/plan-workflow`   | Heavyweight parallel-agent planning. Multi-task features. Artifact output.                                                                              |
| `/parallel-plan`   | Lower-level component of `/plan-workflow` for dependency-aware plans.                                                                               |

### Which `--parallel` should I use?

- **`/plan --parallel`** — You want a quick parallel-capable plan without creating an artifact file. Planner does its own research. Best for small/medium features.
- **`/prp-plan --parallel`** — You want research fan-out (3 parallel researchers covering 8 categories) plus a full artifact file with patterns to mirror and validation commands. Best for medium/large features where you want a rigorous, auditable plan.
- **`/plan-workflow`** — You want heavyweight team orchestration with shared context and multi-phase validation. Best for very large features spanning many tasks.

### When to use `--team`

`--team` is a **opencode-only** execution mode. Cursor and Codex bundles ship
without the team tools (`spawn coordinated subagents`, `send follow-up instructions`, etc.), so invoking `--team`
there has no effect — use `--parallel` instead.

- **`/plan --team`** — The task is complex enough that you want architect, risk, and testing perspectives but not heavy enough for an artifact file. Outputs a merged multi-perspective plan in the conversation.
- **`/plan --parallel --team`** — Same as above, but the merged plan is also formatted for parallel implementation (Batches section, `Depends on` annotations).
- **`/prp-plan --team`** — Team-coordinated research with shared the todo tracker for medium/large features that will produce an artifact file.
- **`/prp-implement --team`** — Team-coordinated execution with shared the todo tracker across all batches. Best for implementation runs where you want coordinated inter-batch shutdown and a single shared task graph.

### When to use `--worktree`

Add `--worktree` whenever you want the plan consumer to isolate each parallel task in its own git worktree. The flag is additive — combine freely with `--parallel` and `--team`:

- **`/plan --worktree --parallel <request>`** — Parallel-capable plan with full worktree annotations (parent path, per-task child paths, `**Worktree**:` fields). Hand off to `/prp-implement --worktree` for isolated execution.
- **`/plan --worktree --parallel --team <request>`** — Multi-perspective plan formatted for both parallel execution and worktree isolation.
