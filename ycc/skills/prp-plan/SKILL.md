---
name: prp-plan
description: Create a comprehensive, self-contained feature implementation plan with codebase pattern extraction and optional external research. Detects whether the input is a PRD (selects next pending phase) or a free-form description, runs deep codebase discovery via ycc:prp-researcher, and writes a single-pass-ready plan to docs/prps/plans/{name}.plan.md. Pass `--parallel` to fan out research across 3 standalone researcher sub-agents and emit a dependency-batched task list ready for parallel execution by prp-implement. Pass `--team` (Claude Code only) to run the same 3 researchers under a shared TeamCreate/TaskList with coordinated shutdown — heavier but with a shared task graph and observable progress. Pass `--worktree` to annotate the emitted plan with a `## Worktree Setup` section and per-parallel-task `**Worktree**:` fields for git-isolated execution. `--parallel` and `--team` are mutually exclusive; `--worktree` combines freely with either. Use when the user asks for a "PRP plan", "implementation plan from PRD", "feature plan with patterns to mirror", "parallel PRP plan", "team PRP plan", or says "/prp-plan". Adapted from PRPs-agentic-eng by Wirasm.
argument-hint: '[--parallel | --team] [--no-worktree] [--dry-run] <feature description | path/to/prd.md>'
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
  - TeamCreate
  - TeamDelete
  - TaskCreate
  - TaskUpdate
  - TaskList
  - TaskGet
  - SendMessage
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

| Flag            | Effect                                                                                                                                                                                                                                               |
| --------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `--parallel`    | Fan out research into 3 **standalone sub-agent** researchers; emit tasks with batch/dependency annotations. Works in Claude Code, Cursor, and Codex.                                                                                                 |
| `--team`        | (Claude Code only) Fan out the same 3 researchers as **teammates** under a shared `TeamCreate`/`TaskList` with coordinated shutdown via `SendMessage`. Same plan output as `--parallel`, but with shared task-graph observability. Heavier dispatch. |
| `--worktree`    | (legacy — now default; safe to omit) Worktree annotations are emitted by default. Accepted as a silent no-op so existing pipelines continue to work.                                                                                                 |
| `--no-worktree` | Opt out of worktree annotations. The plan will not contain a `## Worktree Setup` section or per-task `**Worktree**:` annotations.                                                                                                                    |
| `--dry-run`     | Only valid with `--team`. Prints the team name and teammate roster, then exits without spawning any teammates.                                                                                                                                       |

Strip the flags. Set `PARALLEL_MODE=true|false`, `AGENT_TEAM_MODE=true|false`, `DRY_RUN=true|false`. Default `WORKTREE_MODE=true`; set `WORKTREE_MODE=false` if `--no-worktree` is present. `--worktree` is accepted as a legacy no-op (matches the default). Remaining text is the feature description or PRD path.

```bash
# Default ON; pass --no-worktree to opt out. --worktree accepted as legacy no-op.
WORKTREE_MODE=true
case " $ARGUMENTS " in
  *" --no-worktree "*) WORKTREE_MODE=false ;;
esac
ARGUMENTS="${ARGUMENTS//--no-worktree/}"
ARGUMENTS="${ARGUMENTS//--worktree/}"  # legacy no-op
```

**Validation**:

- `--parallel` and `--team` are **mutually exclusive**. If both are passed → abort with: `--parallel and --team are mutually exclusive. Pick one.`
- `--dry-run` requires `--team`. If `DRY_RUN=true` and `AGENT_TEAM_MODE=false` → abort with: `--dry-run requires --team.`
- `--no-worktree` is **orthogonal** to `--parallel` and `--team` — it may be combined freely with either flag or used alone to suppress annotations.

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

Dispatch a single `ycc:prp-researcher` agent in codebase mode to cover all 8 categories and 5 traces. Use the discovery table for the plan's Patterns to Mirror section.

**IMPORTANT — Researcher prompt constraints**: Tell the researcher to keep code snippets to **5 lines max** per finding and limit the total response to the discovery table format only — no prose summaries.

By default (`WORKTREE_MODE=true`), append the following directive to the researcher prompt. Omit when `--no-worktree` was passed (`WORKTREE_MODE=false`):

> **WORKTREE MODE:** The plan you are helping to build will include worktree annotations. In the emitted plan, include a `## Worktree Setup` section with a single `**Parent**:` line naming the feature worktree; no `**Children**:` list; no per-task `**Worktree**:` annotations. All tasks (parallel and sequential) share this one feature worktree path. Follow `ycc/skills/_shared/references/worktree-strategy.md` for the naming scheme and annotation format.

### Path B — Parallel sub-agents (`PARALLEL_MODE=true`)

Dispatch **3 `ycc:prp-researcher` agents in a SINGLE message** as **standalone
sub-agents** (no `team_name`):

| Researcher          | Categories                             | Traces                  |
| ------------------- | -------------------------------------- | ----------------------- |
| `patterns-research` | Similar Implementations, Naming, Types | Entry Points, Contracts |
| `quality-research`  | Error Handling, Logging, Tests         | State Changes, Patterns |
| `infra-research`    | Configuration, Dependencies            | Data Flow               |

**IMPORTANT — Researcher prompt constraints**: Tell each researcher to keep code snippets to **5 lines max** per finding and limit the total response to the discovery table format only — no prose summaries.

By default (`WORKTREE_MODE=true`), append the following directive to each researcher prompt. Omit when `--no-worktree` was passed (`WORKTREE_MODE=false`):

> **WORKTREE MODE:** The plan you are helping to build will include worktree annotations. In the emitted plan, include a `## Worktree Setup` section with a single `**Parent**:` line naming the feature worktree; no `**Children**:` list; no per-task `**Worktree**:` annotations. All tasks (parallel and sequential) share this one feature worktree path. Follow `ycc/skills/_shared/references/worktree-strategy.md` for the naming scheme and annotation format.

After all 3 return: merge tables, de-duplicate, verify all 8 categories covered.

### Path C — Agent team (`AGENT_TEAM_MODE=true`, Claude Code only)

> **MANDATORY — AGENT TEAMS REQUIRED**
>
> In Path C you MUST follow the agent-team lifecycle. Do NOT mix standalone sub-agents
> with team dispatch. Every `Agent` call below MUST include `team_name=` AND `name=`.
>
> 1. `TeamCreate` FIRST
> 2. `TaskCreate` for each researcher
> 3. `Agent` with `team_name=` — one message, three calls
> 4. `TaskList` — wait for all teammates to complete
> 5. `SendMessage({type:"shutdown_request"})` — shut down all 3 teammates
> 6. `TeamDelete` — clean up
>
> If `TeamCreate` fails, abort the skill. Refer to
> `${CLAUDE_PLUGIN_ROOT}/skills/_shared/references/agent-team-dispatch.md`
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
  - patterns-research  subagent_type=ycc:prp-researcher  task=Similar Implementations, Naming, Types | Entry Points, Contracts
  - quality-research   subagent_type=ycc:prp-researcher  task=Error Handling, Logging, Tests | State Changes, Patterns
  - infra-research     subagent_type=ycc:prp-researcher  task=Configuration, Dependencies | Data Flow
Batches:     1  (batch 1: patterns-research, quality-research, infra-research)
Dependencies: none  (flat graph)
```

Do **not** call any team/task/agent tools. Exit the skill.

#### C.3 Create the team

```
TeamCreate: team_name="prpp-<sanitized-feature>", description="PRP-plan research team for: <feature description>"
```

On failure, abort.

#### C.4 Register subtasks

Create 3 tasks in the shared task list (flat graph — no dependencies between
researchers):

```
TaskCreate: subject="patterns-research: codebase patterns for <feature>", description="Categories: Similar Implementations, Naming, Types. Traces: Entry Points, Contracts."
TaskCreate: subject="quality-research: codebase quality for <feature>",    description="Categories: Error Handling, Logging, Tests. Traces: State Changes, Patterns."
TaskCreate: subject="infra-research: codebase infrastructure for <feature>", description="Categories: Configuration, Dependencies. Traces: Data Flow."
```

#### C.5 Spawn the 3 teammates (single message, three Agent calls)

Use the same researcher categories/traces table from Path B. Spawn all three in **ONE
message** with **THREE `Agent` tool calls**, each with
`team_name="prpp-<sanitized-feature>"` and the role-specific `name`
(`patterns-research`, `quality-research`, `infra-research`), all using
`subagent_type: "ycc:prp-researcher"` in codebase mode.

Apply the same researcher prompt constraints as Path B: 5-line max snippets, discovery
table format only, no prose summaries.

By default (`WORKTREE_MODE=true`), append the following directive to each teammate prompt. Omit when `--no-worktree` was passed (`WORKTREE_MODE=false`):

> **WORKTREE MODE:** The plan you are helping to build will include worktree annotations. In the emitted plan, include a `## Worktree Setup` section with a single `**Parent**:` line naming the feature worktree; no `**Children**:` list; no per-task `**Worktree**:` annotations. All tasks (parallel and sequential) share this one feature worktree path. Follow `ycc/skills/_shared/references/worktree-strategy.md` for the naming scheme and annotation format.

#### C.6 Monitor and merge

Use `TaskList` to confirm all 3 tasks are `completed` before merging. Merge tables,
de-duplicate, verify all 8 categories covered — same merge logic as Path B.

If a teammate errors:

- One researcher failure → record gap in the merged table; note the missing categories
  in the plan's Patterns to Mirror section so the implementor knows to look manually.
- Two or more failures → abort, shut down remaining teammates, `TeamDelete`, fall
  through to ask the user whether to retry with `--parallel` (sub-agent mode).

#### C.7 Shutdown and cleanup

```
SendMessage(to="patterns-research", message={type:"shutdown_request"})
SendMessage(to="quality-research",  message={type:"shutdown_request"})
SendMessage(to="infra-research",    message={type:"shutdown_request"})
TeamDelete
```

Always `TeamDelete` before continuing to Phase 3.

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

If `PARALLEL_MODE=true` **or** `AGENT_TEAM_MODE=true`, also read `${CLAUDE_PLUGIN_ROOT}/skills/prp-plan/references/parallel-additions.md`. Both modes emit the same parallel-capable plan format (Batches section, hierarchical task IDs, `Depends on` annotations) — they only differ in how the research phase was dispatched.

### Step 2: Write the plan in chunks

**Do NOT generate the entire plan in a single Write call.** Instead:

1. **Write** the initial file with: header through Metadata (+ Batches section if parallel), UX Design, and Mandatory Reading sections
   - By default (`WORKTREE_MODE=true`), include the `## Worktree Setup` section immediately after the Metadata / Batches block and before the first implementation section (see worktree annotation rules below). The section contains a single `**Parent**:` line only. When `--no-worktree` was passed (`WORKTREE_MODE=false`), omit this section.
2. **Edit/append** the Patterns to Mirror section (populated from researcher discovery tables)
3. **Edit/append** the Files to Change + NOT Building sections
4. **Edit/append** the Step-by-Step Tasks section (this is usually the largest — keep each task description concise)
   - All tasks (parallel and sequential) share the single feature worktree. Do NOT add per-task `- **Worktree**: ...` annotation lines.
5. **Edit/append** the Testing Strategy, Validation Commands, Acceptance Criteria, Completion Checklist, Risks, and Notes sections

Each chunk should be a separate Write or Edit call. This prevents any single generation from being too large.

### Worktree annotations (default — `WORKTREE_MODE=true`; skipped when `--no-worktree`)

Derive `<feature-slug>` from the kebab-case plan file name (same value used for `{kebab-case-feature-name}.plan.md`). Derive `<repo>` from `git rev-parse --show-toplevel` basename.

**`## Worktree Setup` section** (top-level, before Batches/implementation):

```markdown
## Worktree Setup

- **Parent**: ~/.claude-worktrees/<repo>-<feature-slug>/ (branch: feat/<feature-slug>)
```

All tasks — parallel and sequential — share this one feature worktree path. No `**Children**:` list and no per-task `**Worktree**:` annotation lines are emitted.

Follow `ycc/skills/_shared/references/worktree-strategy.md` for the full naming scheme and annotation contract.

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
- **Worktree Mode**: [Enabled (default) — plan includes ## Worktree Setup (single feature worktree — **Parent**: line only) | Disabled via --no-worktree]

> Next step: Run `/ycc:prp-implement docs/prps/plans/{name}.plan.md` to execute this plan.
```

---

## Verification

Structural validation is enforced by `validate-prp-plan.sh` in Phase 6.5. The validator
operates on the written plan file — dispatch mode (`--parallel` vs `--team`) is
invisible to it, since both modes emit the same plan format.

For Path C's team lifecycle contract (sanitization, shutdown sequence, failure policy),
refer to:

```
${CLAUDE_PLUGIN_ROOT}/skills/_shared/references/agent-team-dispatch.md
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

- Run `/ycc:prp-implement <plan-path>` to execute this plan
- Run `/ycc:plan` for quick conversational planning without artifacts
- Run `/ycc:plan-workflow` for the heavyweight parallel-agent planning track

**Entry points into this skill** — `prp-spec` and `prp-prd` are parallel paths, not sequential:

- Run `/ycc:prp-spec` for a lightweight single-pass spec when the problem is clear
- Run `/ycc:prp-prd` for interactive hypothesis-driven discovery when the problem is unclear
