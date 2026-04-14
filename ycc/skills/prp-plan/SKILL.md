---
name: prp-plan
description: Create a comprehensive, self-contained feature implementation plan with codebase pattern extraction and optional external research. Detects whether the input is a PRD (selects next pending phase) or a free-form description, runs deep codebase discovery via ycc:prp-researcher, and writes a single-pass-ready plan to docs/prps/plans/{name}.plan.md. Pass `--parallel` to fan out research across 3 researcher agents and emit a dependency-batched task list ready for parallel execution by prp-implement. Use when the user asks for a "PRP plan", "implementation plan from PRD", "feature plan with patterns to mirror", "parallel PRP plan", or says "/prp-plan". Adapted from PRPs-agentic-eng by Wirasm.
argument-hint: '[--parallel] <feature description | path/to/prd.md>'
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
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/prp-plan/scripts/*.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/*.sh:*)'
---

# PRP Plan

Create a detailed, self-contained implementation plan that captures all codebase patterns, conventions, and context needed to implement a feature in a single pass.

> Adapted from PRPs-agentic-eng by Wirasm. Part of the PRP workflow series.

**Core Philosophy**: A great plan contains everything needed to implement without asking further questions.

**Golden Rule**: If you would need to search the codebase during implementation, capture that knowledge NOW.

---

## Phase 0 — DETECT

### Flag Parsing

Extract flags from `$ARGUMENTS`:

| Flag         | Effect                                                                                     |
| ------------ | ------------------------------------------------------------------------------------------ |
| `--parallel` | Fan out research into 3 parallel researchers; emit tasks with batch/dependency annotations |

Strip the flag, set `PARALLEL_MODE=true|false`. Remaining text is the feature description or PRD path.

### Input Detection

| Input Pattern             | Action                                                            |
| ------------------------- | ----------------------------------------------------------------- |
| Path ending in `.prd.md`  | Parse PRD, find next pending phase                                |
| Path ending in `.spec.md` | Read spec, extract requirements and technical approach as context |
| Path to `.md` with phases | Parse phases, find next pending                                   |
| Path to other file        | Read for context, treat as free-form                              |
| Free-form text            | Proceed to Phase 1                                                |
| Empty                     | Ask user what feature to plan                                     |

### PRD Parsing (when input is a PRD)

1. Read the PRD, parse **Implementation Phases**
2. Find next eligible `pending` phase (check dependency chains)
3. Extract phase name, description, acceptance criteria, dependencies
4. Use the phase description as the feature to plan

If no pending phases remain, report all phases complete.

---

## Phase 1 — PARSE

Extract from the input:

- **What** is being built, **Why** it matters, **Who** uses it, **Where** it fits

Format a user story: `As a [user], I want [capability], so that [benefit].`

Assess complexity: Small (1-3 files) | Medium (3-10 files) | Large (10+ files) | XL (20+ files, consider splitting)

### Ambiguity Gate

If the core deliverable is vague, success criteria undefined, multiple valid interpretations exist, or there are major technical unknowns — **STOP and ask the user**. Do NOT guess.

---

## Phase 2 — EXPLORE

Gather codebase intelligence across 8 categories and 5 traces.

**8 categories**: Similar Implementations, Naming Conventions, Error Handling, Logging Patterns, Type Definitions, Test Patterns, Configuration, Dependencies

**5 traces**: Entry Points, Data Flow, State Changes, Contracts, Patterns

### Path A — Sequential (default)

Dispatch a single `ycc:prp-researcher` agent in codebase mode to cover all 8 categories and 5 traces. Use the discovery table for the plan's Patterns to Mirror section.

**IMPORTANT — Researcher prompt constraints**: Tell the researcher to keep code snippets to **5 lines max** per finding and limit the total response to the discovery table format only — no prose summaries.

### Path B — Parallel (`PARALLEL_MODE=true`)

Dispatch **3 `ycc:prp-researcher` agents in a SINGLE message**:

| Researcher          | Categories                             | Traces                  |
| ------------------- | -------------------------------------- | ----------------------- |
| `patterns-research` | Similar Implementations, Naming, Types | Entry Points, Contracts |
| `quality-research`  | Error Handling, Logging, Tests         | State Changes, Patterns |
| `infra-research`    | Configuration, Dependencies            | Data Flow               |

**IMPORTANT — Researcher prompt constraints**: Tell each researcher to keep code snippets to **5 lines max** per finding and limit the total response to the discovery table format only — no prose summaries.

After all 3 return: merge tables, de-duplicate, verify all 8 categories covered.

---

## Phase 3 — RESEARCH

If the feature involves external libraries/APIs, dispatch `ycc:prp-researcher` in external mode. Keep findings to KEY_INSIGHT / APPLIES_TO / GOTCHA / SOURCE format.

If only internal patterns are used, skip: "No external research needed."

---

## Phase 4 — DESIGN

If the feature has UX changes, document before/after user experience and interaction changes.

If purely backend/internal: "Internal change — no user-facing UX transformation."

---

## Phase 5 — ARCHITECT

Define:

- **Approach**: High-level strategy
- **Alternatives Considered**: What was rejected and why
- **Scope**: What WILL be built
- **NOT Building**: What is OUT OF SCOPE

---

## Phase 6 — GENERATE

**CRITICAL: Write the plan progressively in chunks to avoid timeouts.**

Save to `docs/prps/plans/{kebab-case-feature-name}.plan.md`. Create directory first:

```bash
mkdir -p docs/prps/plans
```

### Step 1: Read the template

Read the plan template from `${CLAUDE_PLUGIN_ROOT}/skills/prp-plan/references/plan-template.md`.

If `PARALLEL_MODE=true`, also read `${CLAUDE_PLUGIN_ROOT}/skills/prp-plan/references/parallel-additions.md`.

### Step 2: Write the plan in chunks

**Do NOT generate the entire plan in a single Write call.** Instead:

1. **Write** the initial file with: header through Metadata (+ Batches section if parallel), UX Design, and Mandatory Reading sections
2. **Edit/append** the Patterns to Mirror section (populated from researcher discovery tables)
3. **Edit/append** the Files to Change + NOT Building sections
4. **Edit/append** the Step-by-Step Tasks section (this is usually the largest — keep each task description concise)
5. **Edit/append** the Testing Strategy, Validation Commands, Acceptance Criteria, Completion Checklist, Risks, and Notes sections

Each chunk should be a separate Write or Edit call. This prevents any single generation from being too large.

### Writing guidelines

- **Keep task descriptions concise** — ACTION and VALIDATE are required; IMPLEMENT should be 2-3 sentences max, not full code blocks
- **Patterns to Mirror snippets**: Use the researcher's snippets directly, max 5 lines each
- **Omit sections that don't apply** rather than writing "N/A" for every sub-field
- **Validation commands**: Use actual project commands discovered during exploration

---

## Phase 6.5 — VALIDATE

After writing the plan file, run the structural validator:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/prp-plan/scripts/validate-prp-plan.sh "docs/prps/plans/{name}.plan.md"
```

### On errors (exit 1):

Review the error output. For each error:

- **Missing section**: Edit the plan file to add the section with appropriate content from the research phases
- **Missing task fields**: Edit affected tasks to add ACTION and VALIDATE at minimum
- **Invalid file paths**: Verify the path using Glob, then fix the path in the plan
- **Placeholder text**: Replace with actual content from codebase exploration

Re-run the validator **once** after fixes. If it still fails, include the validation output in the report to the user so they are aware of remaining issues.

### On warnings only (exit 0):

Include a brief note in the report: "Plan validated with N warning(s) — see validator output for details."

**Do NOT loop more than once.** One fix pass maximum.

---

## Output

### Update PRD (if input was a PRD)

Update the phase status from `pending` to `in-progress` and add the plan file path.

### Report to User

```
## Plan Created

- **File**: docs/prps/plans/{name}.plan.md
- **Source PRD**: [path or "N/A"]
- **Phase**: [phase name or "standalone"]
- **Complexity**: [level]
- **Scope**: [N files, M tasks]
- **Key Patterns**: [top 3 discovered patterns]
- **External Research**: [topics or "none needed"]
- **Risks**: [top risk or "none identified"]
- **Confidence Score**: [1-10]
- **Execution Mode**: [Sequential | Parallel (N batches, max width X)]

> Next step: Run `/ycc:prp-implement docs/prps/plans/{name}.plan.md` to execute this plan.
```

---

## Verification

Structural validation is enforced by `validate-prp-plan.sh` in Phase 6.5. The script checks:

- Required and recommended sections from the PRP plan template
- Task field completeness (ACTION, VALIDATE required; MIRROR, IMPLEMENT recommended)
- File path existence for Files to Change and Mandatory Reading
- Parallel-mode integrity (if Batches section present)
- Placeholder text detection
- Self-containment heuristic (percentage of tasks with all 4 core fields)

---

## Next Steps

- Run `/ycc:prp-implement <plan-path>` to execute this plan
- Run `/ycc:plan` for quick conversational planning without artifacts
- Run `/ycc:plan-workflow` for the heavyweight parallel-agent planning track

**Entry points into this skill** — `prp-spec` and `prp-prd` are parallel paths, not sequential:

- Run `/ycc:prp-spec` for a lightweight single-pass spec when the problem is clear
- Run `/ycc:prp-prd` for interactive hypothesis-driven discovery when the problem is unclear
