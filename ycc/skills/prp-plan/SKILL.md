---
name: prp-plan
description: Create a comprehensive, self-contained feature implementation plan with codebase pattern extraction and optional external research. Detects whether the input is a PRD (selects next pending phase) or a free-form description, runs deep codebase discovery via ycc:prp-researcher, and writes a single-pass-ready plan to docs/prps/plans/{name}.plan.md. Pass `--parallel` to fan out research across 3 researcher agents and emit a dependency-batched task list ready for parallel execution by prp-implement. Use when the user asks for a "PRP plan", "implementation plan from PRD", "feature plan with patterns to mirror", "parallel PRP plan", or says "/prp-plan". Adapted from PRPs-agentic-eng by Wirasm.
argument-hint: '<feature description | path/to/prd.md> [--parallel]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - Agent
  - WebSearch
  - WebFetch
  - AskUserQuestion
  - TodoWrite
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - Bash(git:*)
---

# PRP Plan

Create a detailed, self-contained implementation plan that captures all codebase patterns, conventions, and context needed to implement a feature in a single pass.

> Adapted from PRPs-agentic-eng by Wirasm. Part of the PRP workflow series.

**Core Philosophy**: A great plan contains everything needed to implement without asking further questions. Every pattern, every convention, every gotcha — captured once, referenced throughout.

**Golden Rule**: If you would need to search the codebase during implementation, capture that knowledge NOW in the plan.

---

## Phase 0 — DETECT

### Flag Parsing

Before detecting input type, extract flags from `$ARGUMENTS`:

| Flag         | Effect                                                                                                                                                            |
| ------------ | ----------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--parallel` | (1) Fan out codebase research into 3 parallel `ycc:prp-researcher` agents covering all 8 categories; (2) emit tasks with `Depends on [...]` annotations grouped into batches for downstream parallel execution via `/ycc:prp-implement --parallel` |

Strip the flag from `$ARGUMENTS` and set `PARALLEL_MODE=true|false`. The remaining text is the feature description or PRD path.

If no flag is provided, default behavior is unchanged (single researcher, sequential task list).

### Input Detection

Determine input type from the stripped `$ARGUMENTS`:

| Input Pattern                              | Detection           | Action                                    |
| ------------------------------------------ | ------------------- | ----------------------------------------- |
| Path ending in `.prd.md`                   | File path to PRD    | Parse PRD, find next pending phase        |
| Path to `.md` with "Implementation Phases" | PRD-like document   | Parse phases, find next pending           |
| Path to any other file                     | Reference file      | Read file for context, treat as free-form |
| Free-form text                             | Feature description | Proceed directly to Phase 1               |
| Empty / blank                              | No input            | Ask user what feature to plan             |

### PRD Parsing (when input is a PRD)

1. Read the PRD file
2. Parse the **Implementation Phases** section
3. Find phases by status:
   - Look for `pending` phases
   - Check dependency chains (a phase may depend on prior phases being `complete`)
   - Select the **next eligible pending phase**
4. Extract from the selected phase:
   - Phase name and description
   - Acceptance criteria
   - Dependencies on prior phases
   - Any scope notes or constraints
5. Use the phase description as the feature to plan

If no pending phases remain, report that all phases are complete.

---

## Phase 1 — PARSE

Extract and clarify the feature requirements.

### Feature Understanding

From the input (PRD phase or free-form description), identify:

- **What** is being built (concrete deliverable)
- **Why** it matters (user value)
- **Who** uses it (target user/system)
- **Where** it fits (which part of the codebase)

### User Story

Format as:

```
As a [type of user],
I want [capability],
So that [benefit].
```

### Complexity Assessment

| Level      | Indicators                                                    | Typical Scope                 |
| ---------- | ------------------------------------------------------------- | ----------------------------- |
| **Small**  | Single file, isolated change, no new dependencies             | 1–3 files, <100 lines         |
| **Medium** | Multiple files, follows existing patterns, minor new concepts | 3–10 files, 100–500 lines     |
| **Large**  | Cross-cutting concerns, new patterns, external integrations   | 10+ files, 500+ lines         |
| **XL**     | Architectural changes, new subsystems, migration needed       | 20+ files, consider splitting |

### Ambiguity Gate

If any of these are unclear, **STOP and ask the user** before proceeding:

- The core deliverable is vague
- Success criteria are undefined
- There are multiple valid interpretations
- Technical approach has major unknowns

Do NOT guess. Ask. A plan built on assumptions fails during implementation.

---

## Phase 2 — EXPLORE

Goal: gather deep codebase intelligence across 8 discovery categories and 5 traces. The shape of this phase depends on `PARALLEL_MODE`.

The 8 categories to cover:

1. Similar Implementations
2. Naming Conventions
3. Error Handling
4. Logging Patterns
5. Type Definitions
6. Test Patterns
7. Configuration
8. Dependencies

The 5 traces to return:

1. Entry Points
2. Data Flow
3. State Changes
4. Contracts
5. Patterns

### Path A — Sequential (default, `PARALLEL_MODE=false`)

Dispatch a single **`ycc:prp-researcher`** agent in **codebase mode** to cover all 8 categories and 5 traces in one pass. The researcher returns a unified discovery table with file:line references.

Use the discovery table verbatim for the plan's **Patterns to Mirror** section below.

### Path B — Parallel Fan-Out (`PARALLEL_MODE=true`)

Dispatch **3 `ycc:prp-researcher` agents in parallel** in a SINGLE message with MULTIPLE `Agent` tool calls. Each agent is assigned a slice of the 8 categories:

| Researcher          | Categories                                          | Traces                     |
| ------------------- | --------------------------------------------------- | -------------------------- |
| `patterns-research` | 1. Similar Implementations, 2. Naming, 5. Types     | Entry Points, Contracts    |
| `quality-research`  | 3. Error Handling, 4. Logging, 6. Tests             | State Changes, Patterns    |
| `infra-research`    | 7. Configuration, 8. Dependencies                   | Data Flow                  |

Each agent is instructed to return its slice as a discovery table with file:line references, in the same format as the sequential researcher.

**After all 3 return**:

1. Merge the three discovery tables into a single unified table
2. De-duplicate overlapping findings (same file:line may appear in multiple slices)
3. Verify all 8 categories are covered — if any are missing, dispatch a follow-up researcher for the gap
4. Use the merged table verbatim for the plan's **Patterns to Mirror** section

**Why 3 agents, not 8**: Keeps fan-out bounded and matches natural research groupings (code style, quality/observability, infrastructure). All 8 categories are still fully covered — just split across 3 workers instead of 1.

---

## Phase 3 — RESEARCH

If the feature involves external libraries, APIs, or unfamiliar technology, dispatch **`ycc:prp-researcher`** in **external mode** to research:

1. Official documentation for the library/API
2. Usage examples and best practices
3. Version-specific gotchas

The researcher formats findings as:

```
KEY_INSIGHT: [what you learned]
APPLIES_TO: [which part of the plan this affects]
GOTCHA: [any warnings or version-specific issues]
SOURCE: [URL]
```

If the feature uses only well-understood internal patterns, skip this phase and note: "No external research needed — feature uses established internal patterns."

---

## Phase 4 — DESIGN

### UX Transformation (if applicable)

Document the before/after user experience:

**Before:**

```
+-----------------------------+
|  [Current user experience]  |
|  Show the current flow,     |
|  what the user sees/does    |
+-----------------------------+
```

**After:**

```
+-----------------------------+
|  [New user experience]      |
|  Show the improved flow,    |
|  what changes for the user  |
+-----------------------------+
```

### Interaction Changes

| Touchpoint | Before | After | Notes |
| ---------- | ------ | ----- | ----- |
| ...        | ...    | ...   | ...   |

If the feature is purely backend/internal with no UX change, note: "Internal change — no user-facing UX transformation."

---

## Phase 5 — ARCHITECT

### Strategic Design

Define the implementation approach:

- **Approach**: High-level strategy (e.g., "Add new service layer following existing repository pattern")
- **Alternatives Considered**: What other approaches were evaluated and why they were rejected
- **Scope**: Concrete boundaries of what WILL be built
- **NOT Building**: Explicit list of what is OUT OF SCOPE (prevents scope creep during implementation)

---

## Phase 6 — GENERATE

Write the full plan document using the template below. Save to `docs/prps/plans/{kebab-case-feature-name}.plan.md`.

Create the directory if it doesn't exist:

```bash
mkdir -p docs/prps/plans
```

### Plan Template

````markdown
# Plan: [Feature Name]

## Summary

[2-3 sentence overview]

## User Story

As a [user], I want [capability], so that [benefit].

## Problem → Solution

[Current state] → [Desired state]

## Metadata

- **Complexity**: [Small | Medium | Large | XL]
- **Source PRD**: [path or "N/A"]
- **PRD Phase**: [phase name or "N/A"]
- **Estimated Files**: [count]

---

## UX Design

### Before

[ASCII diagram or "N/A — internal change"]

### After

[ASCII diagram or "N/A — internal change"]

### Interaction Changes

| Touchpoint | Before | After | Notes |
| ---------- | ------ | ----- | ----- |

---

## Mandatory Reading

Files that MUST be read before implementing:

| Priority       | File           | Lines | Why                    |
| -------------- | -------------- | ----- | ---------------------- |
| P0 (critical)  | `path/to/file` | 1-50  | Core pattern to follow |
| P1 (important) | `path/to/file` | 10-30 | Related types          |
| P2 (reference) | `path/to/file` | all   | Similar implementation |

## External Documentation

| Topic | Source | Key Takeaway |
| ----- | ------ | ------------ |
| ...   | ...    | ...          |

---

## Patterns to Mirror

Code patterns discovered in the codebase. Follow these exactly.

### NAMING_CONVENTION

```
// SOURCE: [file:lines]
[actual code snippet showing the naming pattern]
```

### ERROR_HANDLING

```
// SOURCE: [file:lines]
[actual code snippet showing error handling]
```

### LOGGING_PATTERN

```
// SOURCE: [file:lines]
[actual code snippet showing logging]
```

### REPOSITORY_PATTERN

```
// SOURCE: [file:lines]
[actual code snippet showing data access]
```

### SERVICE_PATTERN

```
// SOURCE: [file:lines]
[actual code snippet showing service layer]
```

### TEST_STRUCTURE

```
// SOURCE: [file:lines]
[actual code snippet showing test setup]
```

---

## Files to Change

| File                  | Action | Justification           |
| --------------------- | ------ | ----------------------- |
| `path/to/file.ts`     | CREATE | New service for feature |
| `path/to/existing.ts` | UPDATE | Add new method          |

## NOT Building

- [Explicit item 1 that is out of scope]
- [Explicit item 2 that is out of scope]

---

## Step-by-Step Tasks

### Task 1: [Name]

- **ACTION**: [What to do]
- **IMPLEMENT**: [Specific code/logic to write]
- **MIRROR**: [Pattern from Patterns to Mirror section to follow]
- **IMPORTS**: [Required imports]
- **GOTCHA**: [Known pitfall to avoid]
- **VALIDATE**: [How to verify this task is correct]

### Task 2: [Name]

- **ACTION**: ...
- **IMPLEMENT**: ...
- **MIRROR**: ...
- **IMPORTS**: ...
- **GOTCHA**: ...
- **VALIDATE**: ...

[Continue for all tasks...]

---

## Testing Strategy

### Unit Tests

| Test | Input | Expected Output | Edge Case? |
| ---- | ----- | --------------- | ---------- |
| ...  | ...   | ...             | ...        |

### Edge Cases Checklist

- [ ] Empty input
- [ ] Maximum size input
- [ ] Invalid types
- [ ] Concurrent access
- [ ] Network failure (if applicable)
- [ ] Permission denied

---

## Validation Commands

### Static Analysis

```bash
# Run type checker
[project-specific type check command]
```

EXPECT: Zero type errors

### Unit Tests

```bash
# Run tests for affected area
[project-specific test command]
```

EXPECT: All tests pass

### Full Test Suite

```bash
# Run complete test suite
[project-specific full test command]
```

EXPECT: No regressions

### Database Validation (if applicable)

```bash
# Verify schema/migrations
[project-specific db command]
```

EXPECT: Schema up to date

### Browser Validation (if applicable)

```bash
# Start dev server and verify
[project-specific dev server command]
```

EXPECT: Feature works as designed

### Manual Validation

- [ ] [Step-by-step manual verification checklist]

---

## Acceptance Criteria

- [ ] All tasks completed
- [ ] All validation commands pass
- [ ] Tests written and passing
- [ ] No type errors
- [ ] No lint errors
- [ ] Matches UX design (if applicable)

## Completion Checklist

- [ ] Code follows discovered patterns
- [ ] Error handling matches codebase style
- [ ] Logging follows codebase conventions
- [ ] Tests follow test patterns
- [ ] No hardcoded values
- [ ] Documentation updated (if needed)
- [ ] No unnecessary scope additions
- [ ] Self-contained — no questions needed during implementation

## Risks

| Risk | Likelihood | Impact | Mitigation |
| ---- | ---------- | ------ | ---------- |
| ...  | ...        | ...    | ...        |

## Notes

[Any additional context, decisions, or observations]
````

### Parallel Mode Additions (`PARALLEL_MODE=true` only)

When `--parallel` is enabled, augment the template above with the following changes. **Do NOT apply these in sequential mode.**

#### 1. Add a `Batches` section after `Metadata`

```markdown
## Batches

Tasks grouped by dependency for parallel execution. Tasks within the same batch run concurrently; batches run in order.

| Batch | Tasks         | Depends On | Parallel Width |
| ----- | ------------- | ---------- | -------------- |
| B1    | 1.1, 1.2, 1.3 | —          | 3              |
| B2    | 2.1           | B1         | 1              |
| B3    | 3.1, 3.2      | B2         | 2              |

- **Total tasks**: [N]
- **Total batches**: [M]
- **Max parallel width**: [X]
```

#### 2. Use hierarchical task IDs and add `Depends on` annotations

Replace the flat `Task 1`, `Task 2` format with hierarchical IDs matching the batch assignment. Add a `BATCH` field and a `Depends on` annotation in the task header.

```markdown
### Task 1.1: [Name] — Depends on [none]

- **BATCH**: B1
- **ACTION**: [What to do]
- **IMPLEMENT**: [Specific code/logic]
- **MIRROR**: [Pattern reference from Patterns to Mirror]
- **IMPORTS**: [Required imports]
- **GOTCHA**: [Known pitfall]
- **VALIDATE**: [How to verify this task]

### Task 2.1: [Name] — Depends on [1.1, 1.2]

- **BATCH**: B2
- **ACTION**: ...
```

#### 3. Batch Construction Rules

When assigning tasks to batches, follow these rules:

- Tasks with no dependencies go in **Batch 1**
- A task joins the **earliest batch** where all its dependencies are already in prior batches
- **Tasks modifying the same file MUST be in different batches** (no concurrent writes to the same file)
- Cross-cutting changes (shared types, global config) get their own dedicated batch, typically **Batch 1** so downstream tasks can depend on them
- Prefer **wide-shallow** dependency graphs (many independent tasks per batch) over **narrow-deep** chains — maximize parallel width

#### 4. Safety Checks Before Finalizing

Before writing the plan, verify:

- [ ] Every task has exactly one `BATCH` assignment
- [ ] Every `Depends on` reference points to a real prior task
- [ ] No two tasks in the same batch touch the same file
- [ ] The dependency graph has no cycles
- [ ] The `Batches` table matches the task assignments exactly

---

## Output

### Save the Plan

Write the generated plan to:

```
docs/prps/plans/{kebab-case-feature-name}.plan.md
```

### Update PRD (if input was a PRD)

If this plan was generated from a PRD phase:

1. Update the phase status from `pending` to `in-progress`
2. Add the plan file path as a reference in the phase

### Report to User

```
## Plan Created

- **File**: docs/prps/plans/{kebab-case-feature-name}.plan.md
- **Source PRD**: [path or "N/A"]
- **Phase**: [phase name or "standalone"]
- **Complexity**: [level]
- **Scope**: [N files, M tasks]
- **Key Patterns**: [top 3 discovered patterns]
- **External Research**: [topics researched or "none needed"]
- **Risks**: [top risk or "none identified"]
- **Confidence Score**: [1-10] — likelihood of single-pass implementation
- **Execution Mode**: [Sequential | Parallel (N batches, max width X)]

> Next step (sequential mode): Run `/ycc:prp-implement docs/prps/plans/{name}.plan.md` to execute this plan.
>
> Next step (parallel mode): Run `/ycc:prp-implement --parallel docs/prps/plans/{name}.plan.md` to execute batches in parallel.
```

---

## Verification

Before finalizing, verify the plan against these checklists:

### Context Completeness

- [ ] All relevant files discovered and documented
- [ ] Naming conventions captured with examples
- [ ] Error handling patterns documented
- [ ] Test patterns identified
- [ ] Dependencies listed

### Implementation Readiness

- [ ] Every task has ACTION, IMPLEMENT, MIRROR, and VALIDATE
- [ ] No task requires additional codebase searching
- [ ] Import paths are specified
- [ ] GOTCHAs documented where applicable

### Pattern Faithfulness

- [ ] Code snippets are actual codebase examples (not invented)
- [ ] SOURCE references point to real files and line numbers
- [ ] Patterns cover naming, errors, logging, data access, and tests
- [ ] New code will be indistinguishable from existing code

### Validation Coverage

- [ ] Static analysis commands specified
- [ ] Test commands specified
- [ ] Build verification included

### UX Clarity

- [ ] Before/after states documented (or marked N/A)
- [ ] Interaction changes listed
- [ ] Edge cases for UX identified

### No Prior Knowledge Test

A developer unfamiliar with this codebase should be able to implement the feature using ONLY this plan, without searching the codebase or asking questions. If not, add the missing context.

---

## Next Steps

- Run `/ycc:prp-implement <plan-path>` to execute this plan
- Run `/ycc:plan` for quick conversational planning without artifacts
- Run `/ycc:prp-prd` to create a PRD first if scope is unclear
- Run `/ycc:plan-workflow` for the parallel-agent planning track (multi-task features)
