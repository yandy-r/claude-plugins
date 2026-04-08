---
name: plan
description: Lightweight conversational planner that restates requirements, identifies risks, and creates a step-by-step implementation plan — then WAITS for explicit user confirmation before any code is written. Use for quick planning on a new feature, architectural change, or complex refactor when you do NOT need the heavier parallel-agent plan-workflow or the PRD-driven prp-plan. Use when the user asks to "plan this", "outline an approach", "break this down before I code", or says "/plan".
argument-hint: '<what you want to plan>'
allowed-tools:
  - Read
  - Grep
  - Glob
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

1. **Restate Requirements** — Clarify what needs to be built in your own words
2. **Identify Risks** — Surface potential issues and blockers
3. **Create Step Plan** — Break down implementation into phases
4. **Wait for Confirmation** — MUST receive explicit user approval before proceeding

## When to Use

Use this skill when:

- Starting a new feature
- Making significant architectural changes
- Working on complex refactoring
- Multiple files/components will be affected
- Requirements are unclear or ambiguous

---

## Process

### Step 1 — Analyze the request

Read the user's input and any referenced files. Check the codebase briefly to confirm feasibility — but do not do deep pattern extraction here (that's `prp-plan`'s job).

### Step 2 — Restate requirements

Paraphrase what the user wants in clear, testable terms. If anything is ambiguous, ask a focused question before drafting the plan.

### Step 3 — Draft the plan

Produce output in this exact format:

```markdown
# Implementation Plan: {Feature Name}

## Requirements Restatement

- {Restated requirement 1}
- {Restated requirement 2}
- {Restated requirement 3}

## Implementation Phases

### Phase 1: {Name}

- {Specific, actionable step}
- {Specific, actionable step}
- {Specific, actionable step}

### Phase 2: {Name}

- {Specific, actionable step}
- {Specific, actionable step}

### Phase 3: {Name}

- {Specific, actionable step}

{Continue as needed — keep phases small and independent where possible}

## Dependencies

- {External library, service, or internal module required}
- {Another dependency}

## Risks

- **HIGH**: {risk and why it matters}
- **MEDIUM**: {risk and why it matters}
- **LOW**: {risk and why it matters}

## Estimated Complexity: {HIGH | MEDIUM | LOW}

- {Subsystem}: rough effort
- {Subsystem}: rough effort

**WAITING FOR CONFIRMATION**: Proceed with this plan? (yes / no / modify)
```

### Step 4 — WAIT

Do not touch any code until the user responds.

Valid user responses:

- **"yes" / "proceed" / "approved"** → proceed to implement
- **"modify: ..."** → adjust the plan and re-present
- **"different approach: ..."** → discard and draft a new approach
- **"skip phase N and do phase M first"** → reorder and re-present
- **"no"** → stop, do not implement

---

## Important Notes

**CRITICAL**: This skill will NOT write any code until the user explicitly confirms.

Do not summarize, do not touch files, do not run commands beyond read-only analysis. Wait.

If the user's instructions are unclear after you draft the plan, ask a focused clarifying question rather than guessing.

---

## Integration with ycc

After planning, depending on what the user approves:

- Use `/ycc:prp-implement` if they want rigorous per-task validation loops (requires a PRP-format plan file — consider running `/ycc:prp-plan` first if you want that workflow)
- Use `/ycc:implement-plan` if the work was structured via `/ycc:parallel-plan`
- Use `/ycc:code-review` to review completed implementation
- Use `/ycc:git-workflow` or `/ycc:prp-commit` to commit

---

## Comparison with other ycc planning tracks

| Track                   | When to use                                                                 |
| ----------------------- | --------------------------------------------------------------------------- |
| `/ycc:plan` (this one)  | Quick conversational plan. No artifact file. Output is inline.             |
| `/ycc:prp-plan`         | Artifact-producing plan with codebase pattern extraction. Single-pass.     |
| `/ycc:prp-prd`          | Interactive PRD first, then prp-plan. Problem-first hypothesis workflow.   |
| `/ycc:plan-workflow`    | Heavyweight parallel-agent planning. Multi-task features. Artifact output. |
| `/ycc:parallel-plan`    | Lower-level component of `/ycc:plan-workflow` for dependency-aware plans.  |
