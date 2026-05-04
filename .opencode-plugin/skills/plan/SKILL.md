---
name: plan
description: Lightweight conversational planner that dispatches the planner agent
  (or a multi-perspective agent team) to produce a specific, phased implementation
  plan with file paths, dependencies, risks, and a testing strategy — then WAITS for
  explicit user confirmation before any code is written. Pass `--parallel` to instruct
  the planner to shape its output for parallel execution (Batches summary section,
  hierarchical step IDs, explicit Depends on annotations). Pass `--team` to spawn
  a 3-persona team (architect / risk-analyst / test-strategist) and merge their outputs
  into a richer plan. Pass `--enhanced` to grow the team from 3 to 5 personas, adding
  security-reviewer and ux-reviewer for explicit security and user-facing perspectives
  (auto-promotes to team mode). Flags are independent and combinable. Use for quick
  planning on a new feature, architectural change, or complex refactor when you do
  NOT need the heavier parallel-agent plan-workflow or the PRD-driven prp-plan.
---

# Plan Skill

Create a comprehensive implementation plan before writing any code. This is the lightweight conversational planner. For heavier planning tracks, see the comparison table at the bottom.

**Core rule**: You will **NOT** write any code until the user explicitly confirms the plan with "yes", "proceed", "approved", or similar affirmative.

---

## What This Skill Does

1. **Parse flags and the request** — Extract `--parallel`, `--team`, `--enhanced`, `--dry-run`, then read the user input and any referenced files
2. **Dispatch planner(s)** — Either dispatch a single `planner` (default) or deploy a 3-persona team (`--team`) or 5-persona team (`--enhanced`, auto-promotes to team mode). In parallel mode, augment the prompt(s) with output-shape directives
3. **Merge and relay the plan** — For the single-agent path, relay verbatim. For the team path, merge teammate outputs into one unified plan
4. **Wait for confirmation** — MUST receive explicit user approval before proceeding

## Flags

| Flag            | Effect                                                                                                                                                                                                                                                                                                                                                                                                                                              |
| --------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--parallel`    | Instruct the planner(s) to emit a parallel-capable plan: a `Batches` summary section at the top, hierarchical step IDs (`1.1`, `1.2`, `2.1`), and explicit `Depends on [...]` annotations on every step. Enables in-conversation parallel implementation via `implementor` agents, or file-based handoff to `/prp-implement --parallel`.                                                                                                    |
| `--team`        | Dispatch a 3-persona planning team (architect / risk-analyst / test-strategist) under a shared `spawn coordinated subagents`/`the todo tracker` with coordinated shutdown. Produces a richer plan by merging structural, risk, and testing perspectives. Heavier than the default single-agent path.                                                                                                                                                                         |
| `--enhanced`    | (Claude Code only) Grow the team from 3 to **5** personas, adding `security-reviewer` (threat model, input validation, authn/authz, secrets, dependency risk) and `ux-reviewer` (user-facing impact — UI, CLI, API responses, error messages). Auto-promotes to team mode when passed alone. Composes with `--parallel` and `--no-worktree`. Lighter than `/prp-plan --enhanced` (which fans out to 7 researchers and writes an artifact file). |
| `--dry-run`     | Only valid with `--team` or `--enhanced`. Prints the team name and teammate roster (3 baseline or 5 enhanced), then exits without spawning any teammates.                                                                                                                                                                                                                                                                                           |
| `--worktree`    | (legacy — now default; safe to omit) Previously required to emit worktree annotations; the annotations are now emitted by default. Accepted as a silent no-op so existing pipelines continue to work.                                                                                                                                                                                                                                               |
| `--no-worktree` | Opt out of worktree annotations. The plan will not contain a `## Worktree Setup` section or per-task `**Worktree**:` annotations.                                                                                                                                                                                                                                                                                                                   |

**Flag interaction**:

- `--parallel` and `--team` are **independent and combinable**. `--parallel` shapes the plan's _output format_; `--team` switches the _dispatch mechanism_. Pass both for a multi-perspective plan formatted for parallel execution.
- `--enhanced` shapes the _team roster_ (3 → 5 personas). It only meaningfully applies to the team path, so `--enhanced` alone auto-promotes to `--enhanced --team` with a one-line notice. Combine freely with `--parallel` and `--no-worktree`.
- `--dry-run` requires `--team` (or `--enhanced`, which auto-promotes). The single-agent path has nothing to dry-run.
- `--no-worktree` opts out of all worktree annotations. When omitted (the default), the plan emits a `## Worktree Setup` section naming the one feature worktree; all tasks (parallel and sequential) share that single path.

**Compatibility note**: `--team` and `--enhanced` both depend on team tools (`spawn coordinated subagents`, `send follow-up instructions`, etc.) which only opencode ships. In Cursor or Codex bundles, both flags abort with a compatibility message — use `--parallel` instead.

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

**Flag parsing**: Extract `--parallel`, `--team`, `--enhanced`, `--dry-run`, `--no-worktree`, and `--worktree` from `$ARGUMENTS` before processing. Strip them out. Set `PARALLEL_MODE=true|false`, `AGENT_TEAM_MODE=true|false`, `ENHANCED_MODE=true|false`, `DRY_RUN=true|false`. Default `WORKTREE_MODE=true`; set `WORKTREE_MODE=false` if `--no-worktree` is present. `--worktree` is accepted as a legacy no-op (matches the default). The remaining text is the user's request.

```bash
# Default ON; pass --no-worktree to opt out. --worktree accepted as legacy no-op.
WORKTREE_MODE=true
case " $ARGUMENTS " in
  *" --no-worktree "*) WORKTREE_MODE=false ;;
esac
ARGUMENTS="${ARGUMENTS//--no-worktree/}"
ARGUMENTS="${ARGUMENTS//--worktree/}"  # legacy no-op

ENHANCED_MODE=false
case " $ARGUMENTS " in
  *" --enhanced "*) ENHANCED_MODE=true ;;
esac
ARGUMENTS="${ARGUMENTS//--enhanced/}"
```

**Validation**:

- If `ENHANCED_MODE=true` and `AGENT_TEAM_MODE=false` → **auto-promote** to team mode (`AGENT_TEAM_MODE=true`) and print one line: `--enhanced implies --team for /plan; promoting dispatch.` `--enhanced` only shapes the team roster, so the single-agent path has nothing to enhance.
- If `DRY_RUN=true` and `AGENT_TEAM_MODE=false` (after the auto-promote check above) → abort with: `--dry-run requires --team or --enhanced (no-op for the single-agent path).`
- If `--enhanced` (or `--team`) is invoked from a Cursor or Codex bundle, abort with: `--enhanced requires team tools, which Cursor/Codex bundles do not ship. Use --parallel instead.` (For plain `--team` the existing compatibility message stands.)

Read the stripped `$ARGUMENTS`. If it references a file path, read that file for context. If the request is ambiguous, ask a single focused clarifying question **before** dispatching.

### Step 2 — Dispatch

Choose dispatch path based on `AGENT_TEAM_MODE` and `ENHANCED_MODE`:

- **`AGENT_TEAM_MODE=false`** (default) → **Path A**: single `planner` agent.
- **`AGENT_TEAM_MODE=true`, `ENHANCED_MODE=false`** → **Path B**: 3-persona planning team.
- **`AGENT_TEAM_MODE=true`, `ENHANCED_MODE=true`** → **Path B (enhanced)**: 5-persona planning team (3 baseline + `security-reviewer` + `ux-reviewer`). All Path B steps below apply with the wider roster.

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

#### Worktree prompt (default — `WORKTREE_MODE=true`; skipped when `--no-worktree`)

By default, append these directives to the prompt. When `--no-worktree` is passed (`WORKTREE_MODE=false`), omit this block entirely and do not emit any worktree annotations.

```
WORKTREE MODE:

The plan consumer will run all tasks in a single shared git worktree.
In your emitted plan:

1. Add a top-level `## Worktree Setup` section BEFORE the Batches summary
   (or before Implementation Steps when there is no Batches section):

   ## Worktree Setup

   - **Parent**: ~/.claude-worktrees/<repo>-<feature>/ (branch: feat/<feature>)

   All tasks — parallel and sequential — share this one path. Do NOT add a
   `**Children**:` list and do NOT add per-task `**Worktree**:` annotations.

See `.opencode-plugin/skills/_shared/references/worktree-strategy.md` §1–§2 for the
canonical single-worktree contract.
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

Print (when `ENHANCED_MODE=false`):

```
Team name:   plan-<sanitized-request>
Teammates:   3
  - architect       subagent_type=planner                    task=Structural plan, phases, file layout, dependencies
  - risk-analyst    subagent_type=codebase-research-analyst  task=Risks, edge cases, rollback, migration concerns
  - test-strategist subagent_type=test-strategy-planner      task=Testing strategy, validation commands, acceptance criteria
Batches:     1  (batch 1: architect, risk-analyst, test-strategist)
Dependencies: none  (flat graph)
```

Print (when `ENHANCED_MODE=true`):

```
Team name:        plan-<sanitized-request>
Teammates:        5
  - architect         subagent_type=planner                    task=Structural plan, phases, file layout, dependencies
  - risk-analyst      subagent_type=codebase-research-analyst  task=Risks, edge cases, rollback, migration concerns
  - test-strategist   subagent_type=test-strategy-planner      task=Testing strategy, validation commands, acceptance criteria
  - security-reviewer subagent_type=research-specialist        task=Threat model, input validation, authn/authz, secrets, dependency risk
  - ux-reviewer       subagent_type=research-specialist        task=User-facing impact (UI, CLI, API responses, error messages); skip if internal-only
Batches:          1  (batch 1: all 5 teammates)
Dependencies:     none  (flat graph)
```

Do **not** call `spawn coordinated subagents` or any team/task/agent tools. Exit the skill.

#### B.3 Create the team

```
spawn coordinated subagents: team_name="plan-<sanitized-request>", description="Multi-perspective planning team for: <user request>"
```

On failure, abort.

#### B.4 Register subtasks

Create one task per teammate in the shared task list (flat graph — no dependencies). When `ENHANCED_MODE=false`, register **3** tasks; when `ENHANCED_MODE=true`, register **5** tasks (the 3 baseline plus `security-reviewer` and `ux-reviewer`):

```
track the task: subject="architect: structural plan for <user request>", description="..."
track the task: subject="risk-analyst: risks and edge cases for <user request>", description="..."
track the task: subject="test-strategist: testing strategy for <user request>", description="..."
# When ENHANCED_MODE=true, also:
track the task: subject="security-reviewer: threat model for <user request>", description="..."
track the task: subject="ux-reviewer: user-facing impact for <user request>",  description="..."
```

#### B.5 Spawn the teammates (single message, N Agent calls)

When `ENHANCED_MODE=false` (default — 3 personas):

| Teammate name     | `subagent_type`                 | Role focus                                                 |
| ----------------- | ------------------------------- | ---------------------------------------------------------- |
| `architect`       | `planner`                   | Structural plan, phases, file layout, dependencies         |
| `risk-analyst`    | `codebase-research-analyst` | Risks, edge cases, rollback, migration concerns            |
| `test-strategist` | `test-strategy-planner`     | Testing strategy, validation commands, acceptance criteria |

When `ENHANCED_MODE=true` (5 personas):

| Teammate name       | `subagent_type`                 | Role focus                                                                         |
| ------------------- | ------------------------------- | ---------------------------------------------------------------------------------- |
| `architect`         | `planner`                   | Structural plan, phases, file layout, dependencies                                 |
| `risk-analyst`      | `codebase-research-analyst` | Risks, edge cases, rollback, migration concerns                                    |
| `test-strategist`   | `test-strategy-planner`     | Testing strategy, validation commands, acceptance criteria                         |
| `security-reviewer` | `research-specialist`       | Threat model, input validation, authn/authz, secrets handling, dependency risk     |
| `ux-reviewer`       | `research-specialist`       | User-facing impact (UI, CLI, API responses, error messages); skip if internal-only |

Spawn all teammates in **ONE message** with **N `Agent` tool calls** (N=3 or N=5), each with
`team_name="plan-<sanitized-request>"` and the role-specific `name` above.

For the 3 baseline personas, each teammate's prompt MUST include:

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
- If `WORKTREE_MODE=true` (default): append the same worktree directives from Path A
  (section "Worktree prompt") — teammates share the single feature worktree and must
  not emit per-task child paths. Omit when `--no-worktree` was passed.

For `security-reviewer` and `ux-reviewer` (when `ENHANCED_MODE=true`), copy the role-specific prompt verbatim from `~/.config/opencode/skills/plan/references/enhanced-personas.md`. Append the same `PARALLEL_MODE` and `WORKTREE_MODE` directives as above so all 5 teammates emit consistent output.

#### B.6 Monitor and collect results

Use `the todo tracker` to confirm all teammate tasks (3 or 5) are `completed` before merging. If any teammate
errors, record the failure in `the todo tracker` and decide per severity:

- `architect` failure → critical; abort with error, shut down remaining teammates, `end the coordinated run`.
- `risk-analyst` or `test-strategist` failure → record "partial plan — {role} did not
  complete" and proceed with a reduced merge, noting the gap in the relayed plan.
- `security-reviewer` or `ux-reviewer` failure (enhanced only) → non-critical; record the gap
  ("partial plan — {role} did not complete; security/UX coverage may be incomplete") and proceed.

#### B.7 Merge outputs

Synthesize the teammate outputs (3 or 5) into a single unified plan following the standard
`planner` Plan Format. Merging rules:

- **Overview / Summary**: use `architect`'s framing.
- **Architecture Changes / Implementation Steps**: primarily `architect`; fold in
  `risk-analyst`'s findings as per-step risk callouts or a dedicated `## Risks &
Mitigations` section.
- **Testing Strategy / Success Criteria**: use `test-strategist`'s content verbatim.
- **Batches section** (if `PARALLEL_MODE=true`): use `architect`'s numbering; re-index
  if `risk-analyst` or `test-strategist` added follow-on steps.
- When `ENHANCED_MODE=true`, also fold in:
  - **`security-reviewer`** → add a top-level `## Security Considerations` section listing the threat-model findings and validation requirements. If specific steps need callouts (e.g., "input must be validated against …"), also annotate the matching `architect` step with `> **Security**: …`. If `security-reviewer` returned no significant findings, omit the section entirely (do not write "N/A").
  - **`ux-reviewer`** → add a top-level `## UX Impact` section with Before / After / Interaction Changes. If `ux-reviewer` returned "Internal change — no user-facing UX impact", omit the section entirely.
- End with the standard confirmation prompt: `**WAITING FOR CONFIRMATION**: Proceed
with this plan? (yes / no / modify)`

#### B.8 Shutdown and cleanup

After merging (success or partial), shut down every teammate that was spawned (3 or 5), then `end the coordinated run`:

```
send follow-up instructions(to="architect",         message={type:"shutdown_request"})
send follow-up instructions(to="risk-analyst",      message={type:"shutdown_request"})
send follow-up instructions(to="test-strategist",   message={type:"shutdown_request"})
# When ENHANCED_MODE=true, also:
send follow-up instructions(to="security-reviewer", message={type:"shutdown_request"})
send follow-up instructions(to="ux-reviewer",       message={type:"shutdown_request"})
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

After Path B merge, verify the unified plan reflects every spawned perspective:

- `architect` slice: `## Implementation Steps` (or equivalent) is present and non-empty
- `risk-analyst` slice: a `## Risks` / `## Risks & Mitigations` section OR per-step risk callouts are present
- `test-strategist` slice: `## Testing Strategy` is present and non-empty
- When `ENHANCED_MODE=true`, also verify:
  - `security-reviewer` slice: `## Security Considerations` is present **OR** the merged plan documents that no significant security risks were found (e.g., a one-line note in `## Risks` such as "Security-reviewer: no significant risks identified"). Per-step `> **Security**:` callouts also satisfy this check.
  - `ux-reviewer` slice: `## UX Impact` is present **OR** the merged plan documents "Internal change — no user-facing UX impact". Both forms count as covered.

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
- Use `/git-workflow --commit` or `/prp-commit` to commit

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

| Track                  | When to use                                                                                                                                                                                                              |
| ---------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ |
| `/plan` (this one) | Quick conversational plan via `planner` agent. No artifact file. Add `--parallel` to shape the output for parallel execution (no research fan-out). Add `--enhanced` to grow the team to 5 personas (security + UX). |
| `/prp-plan`        | Artifact-producing plan with codebase pattern extraction. Single-pass. Add `--parallel` for 3-researcher fan-out + batched plan. Add `--enhanced` for the full 7-researcher fan-out.                                     |
| `/prp-prd`         | Interactive PRD first, then prp-plan. Problem-first hypothesis workflow.                                                                                                                                                 |
| `/plan-workflow`   | Heavyweight parallel-agent planning. Multi-task features. Artifact output.                                                                                                                                               |
| `/parallel-plan`   | Lower-level component of `/plan-workflow` for dependency-aware plans.                                                                                                                                                |

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

### When to use `--enhanced`

`--enhanced` is also **Claude Code only** (it relies on team tools). It grows the team
from 3 to **5** personas, adding `security-reviewer` and `ux-reviewer`. Reach for it
when the change has plausible security exposure (new endpoint, new input source,
authn/authz touch, secret handling) or user-facing surface (new UI / CLI flag /
API response shape / error path). Skip it for purely internal refactors where no new
threat surface or user touchpoint is introduced.

- **`/plan --enhanced <request>`** — Auto-promotes to team mode and dispatches the 5-persona team. Best for medium-complexity features where a 3-persona plan would miss security or UX considerations.
- **`/plan --enhanced --parallel <request>`** — 5-persona plan formatted for parallel execution (Batches section, `Depends on` annotations).
- **`/plan --enhanced --dry-run <request>`** — Print the 5-persona roster without spawning anyone. Useful to confirm the team shape before paying the dispatch cost.
- **`/prp-plan --enhanced <request>`** — The heavier sibling: 7 researchers, artifact-producing. Use when you want the enhanced perspectives _and_ a saved plan file, not just an in-conversation plan.

### When to use `--no-worktree`

Worktree annotations are emitted by default. Pass `--no-worktree` to suppress the `## Worktree Setup` section and all per-task `**Worktree**:` annotations when you do not intend to use git worktree isolation:

- **`/plan --parallel <request>`** — Parallel-capable plan with full worktree annotations (default). Hand off to `/prp-implement` for isolated execution.
- **`/plan --no-worktree --parallel <request>`** — Parallel-capable plan without worktree annotations. Use when worktree isolation is not desired.
- **`/plan --parallel --team <request>`** — Multi-perspective plan formatted for both parallel execution and worktree isolation (default).
- **`/plan --no-worktree --parallel --team <request>`** — Multi-perspective plan with parallel execution but no worktree annotations.
