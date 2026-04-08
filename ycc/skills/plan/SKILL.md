---
name: plan
description: Lightweight conversational planner that dispatches the ycc:planner agent to produce a specific, phased implementation plan with file paths, dependencies, risks, and a testing strategy — then WAITS for explicit user confirmation before any code is written. Pass `--parallel` to instruct the planner to shape its output for parallel execution (Batches summary section, hierarchical step IDs, explicit Depends on annotations). Use for quick planning on a new feature, architectural change, or complex refactor when you do NOT need the heavier parallel-agent plan-workflow or the PRD-driven prp-plan. Use when the user asks to "plan this", "outline an approach", "break this down before I code", "parallel plan", or says "/plan".
argument-hint: '<what you want to plan> [--parallel]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Agent
  - TodoWrite
  - AskUserQuestion
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(git:*)
---

# Plan Skill

Create a comprehensive implementation plan before writing any code. This is the lightweight conversational planner. For heavier planning tracks, see the comparison table at the bottom.

**Core rule**: You will **NOT** write any code until the user explicitly confirms the plan with "yes", "proceed", "approved", or similar affirmative.

---

## What This Skill Does

1. **Parse flags and the request** — Extract `--parallel`, then read the user input and any referenced files
2. **Dispatch `ycc:planner`** — Delegate plan construction to the planning specialist agent. In parallel mode, augment the prompt with output-shape directives
3. **Relay the plan** — Present the agent's plan to the user verbatim
4. **Wait for confirmation** — MUST receive explicit user approval before proceeding

## Flags

| Flag         | Effect                                                                                                                                                                                                                                                                                                                                                              |
| ------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
| `--parallel` | Instruct the `ycc:planner` agent to emit a parallel-capable plan: a `Batches` summary section at the top, hierarchical step IDs (`1.1`, `1.2`, `2.1`), and explicit `Depends on [...]` annotations on every step. Enables in-conversation parallel implementation via `ycc:implementor` agents, or file-based handoff to `/ycc:prp-implement --parallel`. |

**Note**: `--parallel` on `/ycc:plan` shapes the *output*, not the research phase. The `ycc:planner` agent already does its own codebase reads; this skill does not fan out to multiple researcher agents. For research fan-out on larger features, use `/ycc:prp-plan --parallel`.

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

**Flag parsing**: Extract `--parallel` from `$ARGUMENTS` before processing. Strip it out and set `PARALLEL_MODE=true|false`. The remaining text is the user's request.

Read the stripped `$ARGUMENTS`. If it references a file path, read that file for context. If the request is ambiguous, ask a single focused clarifying question **before** dispatching the agent.

### Step 2 — Dispatch the `ycc:planner` agent

Use the Agent tool with `subagent_type: "ycc:planner"`. In the prompt, include:

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

### Step 3 — Relay the plan

Present the agent's plan to the user verbatim. Do not summarize, do not shorten, do not add your own commentary above it.

### Step 4 — WAIT

Do not touch any code until the user responds.

Valid user responses:

- **"yes" / "proceed" / "approved"** → proceed to implement
- **"modify: ..."** → re-dispatch `ycc:planner` with the modification request and the previous plan as context
- **"different approach: ..."** → discard and re-dispatch `ycc:planner` with the new direction
- **"skip phase N and do phase M first"** → re-dispatch with the reorder request
- **"no"** → stop, do not implement

---

## Important Notes

**CRITICAL**: This skill will NOT write any code until the user explicitly confirms.

Do not summarize, do not touch files, do not run commands beyond read-only analysis. Wait.

If the user's instructions are unclear after the planner produces a draft, ask a focused clarifying question rather than guessing, then re-dispatch the planner with the clarification.

The `ycc:planner` agent owns the plan format, worked examples, sizing/phasing guidance, and red-flag checks. This skill is an orchestration layer — it decides _when_ to plan and _what_ to do with the plan, not _how_ a plan should be structured.

---

## Integration with ycc

After planning, depending on what the user approves:

- Use `/ycc:prp-implement` if they want rigorous per-task validation loops (requires a PRP-format plan file — consider running `/ycc:prp-plan` first if you want that workflow)
- Use `/ycc:implement-plan` if the work was structured via `/ycc:parallel-plan`
- Use `/ycc:code-review` to review completed implementation
- Use `/ycc:git-workflow` or `/ycc:prp-commit` to commit

### Executing a Parallel Plan

If the plan was produced with `--parallel` (has a `Batches` section and `Depends on` annotations), after the user confirms you have two options for parallel execution:

**Option 1 — In-conversation parallel execution (lightweight)**

Process batches sequentially. Within each batch, dispatch one `ycc:implementor` agent per step in a SINGLE message with MULTIPLE `Agent` tool calls. Between batches, run the project's type-check and unit-test commands. On failure, stop and ask the user how to proceed.

This keeps everything in the current conversation — no file artifact needed.

**Option 2 — Save to file and hand off (rigorous)**

Write the plan to `docs/prps/plans/{name}.plan.md` (adapting it to the PRP plan template if needed: add `Patterns to Mirror`, `Files to Change`, `Validation Commands`, etc.), then run `/ycc:prp-implement --parallel docs/prps/plans/{name}.plan.md` for the full 5-level validation pipeline.

Use Option 1 for small features and quick iterations. Use Option 2 when the user wants an implementation report, per-task validation logs, and the plan archived for audit.

---

## Comparison with other ycc planning tracks

| Track                          | When to use                                                                                                                                         |
| ------------------------------ | --------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/ycc:plan` (this one)         | Quick conversational plan via `ycc:planner` agent. No artifact file. Add `--parallel` to shape the output for parallel execution (no research fan-out). |
| `/ycc:prp-plan`                | Artifact-producing plan with codebase pattern extraction. Single-pass. Add `--parallel` for 3-researcher fan-out + batched plan.                     |
| `/ycc:prp-prd`                 | Interactive PRD first, then prp-plan. Problem-first hypothesis workflow.                                                                             |
| `/ycc:plan-workflow`           | Heavyweight parallel-agent planning. Multi-task features. Artifact output.                                                                           |
| `/ycc:parallel-plan`           | Lower-level component of `/ycc:plan-workflow` for dependency-aware plans.                                                                             |

### Which `--parallel` should I use?

- **`/ycc:plan --parallel`** — You want a quick parallel-capable plan without creating an artifact file. Planner does its own research. Best for small/medium features.
- **`/ycc:prp-plan --parallel`** — You want research fan-out (3 parallel researchers covering 8 categories) plus a full artifact file with patterns to mirror and validation commands. Best for medium/large features where you want a rigorous, auditable plan.
- **`/ycc:plan-workflow`** — You want heavyweight team orchestration with shared context and multi-phase validation. Best for very large features spanning many tasks.
