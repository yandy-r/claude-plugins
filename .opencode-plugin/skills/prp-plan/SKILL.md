---
name: prp-plan
description: Create a comprehensive, self-contained feature implementation plan with
  codebase pattern extraction and optional external research. Detects whether the
  input is a PRD (selects next pending phase) or a free-form description, runs deep
  codebase discovery via prp-researcher, and writes a single-pass-ready plan to docs/prps/plans/{name}.plan.md.
  Pass `--parallel` to fan out research across 3 standalone researcher sub-agents
  and emit a dependency-batched task list ready for parallel execution by prp-implement.
  Pass `--team` (Claude Code only) to run the same 3 researchers under a shared spawn
  coordinated subagents/the todo tracker with coordinated shutdown — heavier but with
  a shared task graph and observable progress. Pass `--worktree` to annotate the emitted
  plan with a `## Worktree Setup` section and per-parallel-task `**Worktree**:` fields
  for git-isolated execution. `--parallel` and `--team` are mutually exclusive; `--worktree`
  combines freely with either.
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

| Flag          | Effect                                                                                                                                                                                                                                                                                                                                                  |
| ------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--parallel`  | Fan out research into 3 **standalone sub-agent** researchers; emit tasks with batch/dependency annotations. Works in opencode, Cursor, and Codex.                                                                                                                                                                                                    |
| `--team`      | (Claude Code only) Fan out the same 3 researchers as **teammates** under a shared `spawn coordinated subagents`/`the todo tracker` with coordinated shutdown via `send follow-up instructions`. Same plan output as `--parallel`, but with shared task-graph observability. Heavier dispatch.                                                                                                     |
| `--worktree`  | Annotate the emitted plan with a top-level `## Worktree Setup` section and a `**Worktree**:` field on every parallel task. The plan consumer (`/prp-implement --worktree` or auto-detect) uses these to create per-task git-isolated worktrees. Follows `.opencode-plugin/skills/_shared/references/worktree-strategy.md`. Combines freely with `--parallel` and `--team`. |
| `--dry-run`   | Only valid with `--team`. Prints the team name and teammate roster, then exits without spawning any teammates.                                                                                                                                                                                                                                          |

Strip the flags. Set `PARALLEL_MODE=true|false`, `AGENT_TEAM_MODE=true|false`, `WORKTREE_MODE=true|false`, `DRY_RUN=true|false`. Remaining text is the feature description or PRD path.

**Validation**:

- `--parallel` and `--team` are **mutually exclusive**. If both are passed → abort with: `--parallel and --team are mutually exclusive. Pick one.`
- `--dry-run` requires `--team`. If `DRY_RUN=true` and `AGENT_TEAM_MODE=false` → abort with: `--dry-run requires --team.`
- `--worktree` is **orthogonal** to `--parallel` and `--team` — it may be combined freely with either flag or used alone.

**Compatibility note**: When this skill is invoked from a Cursor or Codex bundle, `--team` must not be used (those bundles ship without team tools). Use `--parallel` instead.

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

Dispatch a single `prp-researcher` agent in codebase mode to cover all 8 categories and 5 traces. Use the discovery table for the plan's Patterns to Mirror section.

**IMPORTANT — Researcher prompt constraints**: Tell the researcher to keep code snippets to **5 lines max** per finding and limit the total response to the discovery table format only — no prose summaries.

If `WORKTREE_MODE=true`, append the following directive to the researcher prompt:

> **WORKTREE MODE:** The plan you are helping to build will include worktree annotations. In the emitted plan, include a `## Worktree Setup` section (parent + per-parallel-task children) and a `**Worktree**:` field on every parallel task. Sequential tasks get no annotation. Follow `.opencode-plugin/skills/_shared/references/worktree-strategy.md` for the naming scheme and annotation format.

### Path B — Parallel sub-agents (`PARALLEL_MODE=true`)

Dispatch **3 `prp-researcher` agents in a SINGLE message** as **standalone
sub-agents** (no `team_name`):

| Researcher          | Categories                             | Traces                  |
| ------------------- | -------------------------------------- | ----------------------- |
| `patterns-research` | Similar Implementations, Naming, Types | Entry Points, Contracts |
| `quality-research`  | Error Handling, Logging, Tests         | State Changes, Patterns |
| `infra-research`    | Configuration, Dependencies            | Data Flow               |

**IMPORTANT — Researcher prompt constraints**: Tell each researcher to keep code snippets to **5 lines max** per finding and limit the total response to the discovery table format only — no prose summaries.

If `WORKTREE_MODE=true`, append the following directive to each researcher prompt:

> **WORKTREE MODE:** The plan you are helping to build will include worktree annotations. In the emitted plan, include a `## Worktree Setup` section (parent + per-parallel-task children) and a `**Worktree**:` field on every parallel task. Sequential tasks get no annotation. Follow `.opencode-plugin/skills/_shared/references/worktree-strategy.md` for the naming scheme and annotation format.

After all 3 return: merge tables, de-duplicate, verify all 8 categories covered.

### Path C — Agent team (`AGENT_TEAM_MODE=true`, Claude Code only)

> **MANDATORY — AGENT TEAMS REQUIRED**
>
> In Path C you MUST follow the agent-team lifecycle. Do NOT mix standalone sub-agents
> with team dispatch. Every `Agent` call below MUST include `team_name=` AND `name=`.
>
> 1. `spawn coordinated subagents` FIRST
> 2. `track the task` for each researcher
> 3. `Agent` with `team_name=` — one message, three calls
> 4. `the todo tracker` — wait for all teammates to complete
> 5. `send follow-up instructions({type:"shutdown_request"})` — shut down all 3 teammates
> 6. `end the coordinated run` — clean up
>
> If `spawn coordinated subagents` fails, abort the skill. Refer to
> `~/.config/opencode/shared/references/agent-team-dispatch.md`
> for the full lifecycle contract.

#### C.1 Build the team name

Sanitize the feature name (kebab-case slug; if input is a PRD, use its filename minus
extension; if free-form text, slugify). Lowercase, kebab, max **20 chars**, fall back
to `untitled` if empty.

Team name: `prpp-<sanitized-feature>`.

#### C.2 Dry-run gate (if `DRY_RUN=true`)

Print:

```
Team name:   prpp-<sanitized-feature>
Teammates:   3
  - patterns-research  subagent_type=prp-researcher  task=Similar Implementations, Naming, Types | Entry Points, Contracts
  - quality-research   subagent_type=prp-researcher  task=Error Handling, Logging, Tests | State Changes, Patterns
  - infra-research     subagent_type=prp-researcher  task=Configuration, Dependencies | Data Flow
Batches:     1  (batch 1: patterns-research, quality-research, infra-research)
Dependencies: none  (flat graph)
```

Do **not** call any team/task/agent tools. Exit the skill.

#### C.3 Create the team

```
spawn coordinated subagents: team_name="prpp-<sanitized-feature>", description="PRP-plan research team for: <feature description>"
```

On failure, abort.

#### C.4 Register subtasks

Create 3 tasks in the shared task list (flat graph — no dependencies between
researchers):

```
track the task: subject="patterns-research: codebase patterns for <feature>", description="Categories: Similar Implementations, Naming, Types. Traces: Entry Points, Contracts."
track the task: subject="quality-research: codebase quality for <feature>",    description="Categories: Error Handling, Logging, Tests. Traces: State Changes, Patterns."
track the task: subject="infra-research: codebase infrastructure for <feature>", description="Categories: Configuration, Dependencies. Traces: Data Flow."
```

#### C.5 Spawn the 3 teammates (single message, three Agent calls)

Use the same researcher categories/traces table from Path B. Spawn all three in **ONE
message** with **THREE `Agent` tool calls**, each with
`team_name="prpp-<sanitized-feature>"` and the role-specific `name`
(`patterns-research`, `quality-research`, `infra-research`), all using
`@prp-researcher` in codebase mode.

Apply the same researcher prompt constraints as Path B: 5-line max snippets, discovery
table format only, no prose summaries.

If `WORKTREE_MODE=true`, append the following directive to each teammate prompt:

> **WORKTREE MODE:** The plan you are helping to build will include worktree annotations. In the emitted plan, include a `## Worktree Setup` section (parent + per-parallel-task children) and a `**Worktree**:` field on every parallel task. Sequential tasks get no annotation. Follow `.opencode-plugin/skills/_shared/references/worktree-strategy.md` for the naming scheme and annotation format.

#### C.6 Monitor and merge

Use `the todo tracker` to confirm all 3 tasks are `completed` before merging. Merge tables,
de-duplicate, verify all 8 categories covered — same merge logic as Path B.

If a teammate errors:

- One researcher failure → record gap in the merged table; note the missing categories
  in the plan's Patterns to Mirror section so the implementor knows to look manually.
- Two or more failures → abort, shut down remaining teammates, `end the coordinated run`, fall
  through to ask the user whether to retry with `--parallel` (sub-agent mode).

#### C.7 Shutdown and cleanup

```
send follow-up instructions(to="patterns-research", message={type:"shutdown_request"})
send follow-up instructions(to="quality-research",  message={type:"shutdown_request"})
send follow-up instructions(to="infra-research",    message={type:"shutdown_request"})
end the coordinated run
```

Always `end the coordinated run` before continuing to Phase 3.

---

## Phase 3 — RESEARCH

If the feature involves external libraries/APIs, dispatch `prp-researcher` in external mode. Keep findings to KEY_INSIGHT / APPLIES_TO / GOTCHA / SOURCE format.

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

Read the plan template from `~/.config/opencode/skills/prp-plan/references/plan-template.md`.

If `PARALLEL_MODE=true` **or** `AGENT_TEAM_MODE=true`, also read `~/.config/opencode/skills/prp-plan/references/parallel-additions.md`. Both modes emit the same parallel-capable plan format (Batches section, hierarchical task IDs, `Depends on` annotations) — they only differ in how the research phase was dispatched.

### Step 2: Write the plan in chunks

**Do NOT generate the entire plan in a single Write call.** Instead:

1. **Write** the initial file with: header through Metadata (+ Batches section if parallel), UX Design, and Mandatory Reading sections
   - If `WORKTREE_MODE=true`, include the `## Worktree Setup` section immediately after the Metadata / Batches block and before the first implementation section (see worktree annotation rules below)
2. **Edit/append** the Patterns to Mirror section (populated from researcher discovery tables)
3. **Edit/append** the Files to Change + NOT Building sections
4. **Edit/append** the Step-by-Step Tasks section (this is usually the largest — keep each task description concise)
   - If `WORKTREE_MODE=true`, add a `- **Worktree**: ...` line inside every **parallel** task block; sequential tasks get no annotation
5. **Edit/append** the Testing Strategy, Validation Commands, Acceptance Criteria, Completion Checklist, Risks, and Notes sections

Each chunk should be a separate Write or Edit call. This prevents any single generation from being too large.

### Worktree annotations (when `WORKTREE_MODE=true`)

Derive `<feature-slug>` from the kebab-case plan file name (same value used for `{kebab-case-feature-name}.plan.md`). Derive `<repo>` from `git rev-parse --show-toplevel` basename.

Normalize task IDs: replace `.` with `-` (e.g., `1.1` → `1-1`).

**`## Worktree Setup` section** (top-level, before Batches/implementation):

```markdown
## Worktree Setup

- **Parent**: ~/.claude-worktrees/<repo>-<feature-slug>/          (branch: feat/<feature-slug>)
- **Children** (per parallel task; merged back at end of each batch):
  - Task 1.1 → ~/.claude-worktrees/<repo>-<feature-slug>-1-1/    (branch: feat/<feature-slug>-1-1)
  - Task 1.2 → ~/.claude-worktrees/<repo>-<feature-slug>-1-2/    (branch: feat/<feature-slug>-1-2)
  - ...
```

List only the parallel tasks enumerated in the Batches / Step-by-Step Tasks sections. Sequential tasks are omitted from the Children list.

**Per-parallel-task inline annotation** (inside the task block, immediately after the task heading line):

```markdown
- **Worktree**: ~/.claude-worktrees/<repo>-<feature-slug>-<task-id>/   (branch: feat/<feature-slug>-<task-id>)
```

Sequential tasks receive **no** `**Worktree**:` annotation.

Follow `.opencode-plugin/skills/_shared/references/worktree-strategy.md` for the full naming scheme and annotation contract.

### Writing guidelines

- **Keep task descriptions concise** — ACTION and VALIDATE are required; IMPLEMENT should be 2-3 sentences max, not full code blocks
- **Patterns to Mirror snippets**: Use the researcher's snippets directly, max 5 lines each
- **Omit sections that don't apply** rather than writing "N/A" for every sub-field
- **Validation commands**: Use actual project commands discovered during exploration

---

## Phase 6.5 — VALIDATE

After writing the plan file, run the structural validator:

```bash
~/.config/opencode/skills/prp-plan/scripts/validate-prp-plan.sh "docs/prps/plans/{name}.plan.md"
```

### On errors (exit 1)

Review the error output. For each error:

- **Missing section**: Edit the plan file to add the section with appropriate content from the research phases
- **Missing task fields**: Edit affected tasks to add ACTION and VALIDATE at minimum
- **Invalid file paths**: Verify the path using Glob, then fix the path in the plan
- **Placeholder text**: Replace with actual content from codebase exploration

Re-run the validator **once** after fixes. If it still fails, include the validation output in the report to the user so they are aware of remaining issues.

### On warnings only (exit 0)

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
- **Research Dispatch**: [Sequential | Parallel sub-agents | Agent team]
- **Execution Mode**: [Sequential | Parallel (N batches, max width X)]
- **Worktree Mode**: [Enabled — plan includes ## Worktree Setup + per-task annotations | Disabled]

> Next step: Run `/prp-implement docs/prps/plans/{name}.plan.md` to execute this plan.
```

---

## Verification

Structural validation is enforced by `validate-prp-plan.sh` in Phase 6.5. The validator
operates on the written plan file — dispatch mode (`--parallel` vs `--team`) is
invisible to it, since both modes emit the same plan format.

For Path C's team lifecycle contract (sanitization, shutdown sequence, failure policy),
refer to:

```
~/.config/opencode/shared/references/agent-team-dispatch.md
```

The `validate-prp-plan.sh` script The script checks:

- Required and recommended sections from the PRP plan template
- Task field completeness (ACTION, VALIDATE required; MIRROR, IMPLEMENT recommended)
- File path existence for Files to Change and Mandatory Reading
- Parallel-mode integrity (if Batches section present)
- Placeholder text detection
- Self-containment heuristic (percentage of tasks with all 4 core fields)

---

## Next Steps

- Run `/prp-implement <plan-path>` to execute this plan
- Run `/plan` for quick conversational planning without artifacts
- Run `/plan-workflow` for the heavyweight parallel-agent planning track

**Entry points into this skill** — `prp-spec` and `prp-prd` are parallel paths, not sequential:

- Run `/prp-spec` for a lightweight single-pass spec when the problem is clear
- Run `/prp-prd` for interactive hypothesis-driven discovery when the problem is unclear
