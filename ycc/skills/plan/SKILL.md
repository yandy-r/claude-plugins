---
name: plan
description: Lightweight conversational planner that dispatches the ycc:planner agent to produce a specific, phased implementation plan with file paths, dependencies, risks, and a testing strategy — then WAITS for explicit user confirmation before any code is written. Use for quick planning on a new feature, architectural change, or complex refactor when you do NOT need the heavier parallel-agent plan-workflow or the PRD-driven prp-plan. Use when the user asks to "plan this", "outline an approach", "break this down before I code", or says "/plan".
argument-hint: '<what you want to plan>'
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

1. **Analyze the request** — Read the user input and any referenced files
2. **Dispatch `ycc:planner`** — Delegate plan construction to the planning specialist agent
3. **Relay the plan** — Present the agent's plan to the user verbatim
4. **Wait for confirmation** — MUST receive explicit user approval before proceeding

## When to Use

Use this skill when:

- Starting a new feature
- Making significant architectural changes
- Working on complex refactoring
- Multiple files/components will be affected
- Requirements are unclear or ambiguous

---

## Process

### Step 1 — Parse the user's request

Read `$ARGUMENTS`. If it references a file path, read that file for context. If the request is ambiguous, ask a single focused clarifying question **before** dispatching the agent.

### Step 2 — Dispatch the `ycc:planner` agent

Use the Agent tool with `subagent_type: "ycc:planner"`. In the prompt, include:

- The user's original request (verbatim)
- Any file paths or context they referenced
- A note that the agent should follow its Plan Format and end with `**WAITING FOR CONFIRMATION**: Proceed with this plan? (yes / no / modify)`

Example prompt to the agent:

```
The user asked: "<user's request>"

Related context they pointed to: <files, URLs, or "none">

Produce a full implementation plan following your Plan Format. Use the
Read/Grep/Glob tools to analyze the codebase and include concrete file
paths. End with your standard confirmation prompt.
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

---

## Comparison with other ycc planning tracks

| Track                  | When to use                                                                |
| ---------------------- | -------------------------------------------------------------------------- |
| `/ycc:plan` (this one) | Quick conversational plan via `ycc:planner` agent. No artifact file.       |
| `/ycc:prp-plan`        | Artifact-producing plan with codebase pattern extraction. Single-pass.     |
| `/ycc:prp-prd`         | Interactive PRD first, then prp-plan. Problem-first hypothesis workflow.   |
| `/ycc:plan-workflow`   | Heavyweight parallel-agent planning. Multi-task features. Artifact output. |
| `/ycc:parallel-plan`   | Lower-level component of `/ycc:plan-workflow` for dependency-aware plans.  |
