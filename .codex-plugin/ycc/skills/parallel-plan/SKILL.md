---
name: parallel-plan
description: Create detailed parallel implementation plans by running analysis and
  validation stages, then synthesizing dependency-aware tasks into parallel-plan.md.
  Use after shared-context to prepare implementation-ready planning artifacts. Defaults
  to standalone parallel sub-agents via the parallel agent workflow; pass `--team`
  (Codex only) to orchestrate the analysis and validation stages as teammates under
  a shared create an agent group/the task tracker with coordinated shutdown.
---

## SCOPE LIMITATION - READ FIRST

**THIS SKILL ONLY CREATES PLANNING ARTIFACTS. IT NEVER IMPLEMENTS.**

- DO NOT execute any implementation tasks
- DO NOT modify application code
- DO NOT run the implement-plan skill
- DO NOT proceed beyond creating planning artifacts

**Outputs**:

- `${PLANS_DIR}/[feature-name]/analysis-context.md`
- `${PLANS_DIR}/[feature-name]/analysis-code.md`
- `${PLANS_DIR}/[feature-name]/analysis-tasks.md`
- `${PLANS_DIR}/[feature-name]/parallel-plan.md`

After creating planning artifacts and displaying the summary, **STOP COMPLETELY**.

---

# Parallel Implementation Plan Creator

Create `parallel-plan.md` by running analysis and validation stages — standalone sub-agents by default, or agent teams with `--team` (Codex only) where teammates share findings with each other — synthesizing implementation tasks, and validating plan quality.

## Workflow Integration

```text
shared-context (step 1) -> parallel-plan (this skill) -> implement-plan (step 3)
```

This skill requires `${feature_dir}/shared.md` and ends after producing analysis artifacts and `parallel-plan.md`.

**BOUNDARY**: This skill ENDS after creating `parallel-plan.md`. The user manually runs `/implement-plan` when ready.

**If shared.md doesn't exist**, run `/shared-context [feature-name]` first.

## Arguments

**Target**: `$ARGUMENTS`

Parse arguments (flags first, then the feature name):

- **--team**: Optional. (Codex only) Deploy the analysis and validation stages as teammates under a shared `create an agent group`/`the task tracker` with coordinated shutdown. Default is standalone parallel sub-agents via the `Task` tool. Cursor and Codex bundles lack team tools — do not pass `--team` there.
- **--dry-run**: Show what would be created without making changes. With `--team`, also prints the team name and teammate roster.
- **feature-name**: Required. Matches directory name in `${PLANS_DIR}`.

If no feature name provided, abort with usage instructions:

```
Usage: /parallel-plan [--team] [feature-name] [--dry-run]

Examples:
  /parallel-plan user-authentication
  /parallel-plan payment-integration --dry-run
  /parallel-plan --team payment-integration
  /parallel-plan --team --dry-run user-authentication
```

---

## Phase 0: Prerequisites and Dry Run Check

### Step 1: Resolve Plans Directory

Use the shared resolver to determine the correct plans directory:

```bash
source ~/.codex/plugins/ycc/shared/scripts/resolve-plans-dir.sh
feature_dir="$(get_feature_plan_dir "[feature-name]")"
```

### Step 2: Parse Arguments and Validate Prerequisites

Extract from `$ARGUMENTS`:

1. **--team**: Boolean flag. Set `AGENT_TEAM_MODE=true` if present, else `false`.
2. **--dry-run**: Boolean flag. Set `DRY_RUN=true` if present, else `false`.
3. **feature-name**: First non-flag argument (required).

**Compatibility note**: When this skill is invoked from a Cursor or Codex bundle, `--team` must not be used (those bundles ship without team tools).

Run the prerequisites check script:

```bash
~/.codex/plugins/ycc/skills/parallel-plan/scripts/check-prerequisites.sh [feature-name]
```

If the script exits with error:

- Display the error message
- Instruct user to run `/shared-context` first to create the shared context document
- **STOP HERE** - do not proceed

### Step 3: Verify Planning Documents

Confirm these files exist in `${feature_dir}/`:

- `shared.md` (required)
- `requirements.md` (optional but helpful)

### Step 4: Handle Dry Run

If `--dry-run` is present in `$ARGUMENTS`:

Display:

```markdown
# Dry Run: Parallel Plan for [feature-name]

## Dispatch Mode

Mode: [standalone sub-agents | agent team pp-[feature-name]]

### Phase 1: Analysis Agents (3)

1. context-synthesizer - Condense planning documentation
2. code-analyzer - Extract code patterns from relevant files
3. task-structurer - Suggest task breakdown and phases

### Phase 2: Validation Agents (3)

1. path-validator - Verify all paths exist
2. dependency-validator - Check dependency graph
3. completeness-validator - Ensure tasks are actionable

## Files That Would Be Created

- ${PLANS_DIR}/[feature-name]/analysis-context.md (by context-synthesizer)
- ${PLANS_DIR}/[feature-name]/analysis-code.md (by code-analyzer)
- ${PLANS_DIR}/[feature-name]/analysis-tasks.md (by task-structurer)
- ${PLANS_DIR}/[feature-name]/parallel-plan.md (final plan)

## Execution Model

- Default (`AGENT_TEAM_MODE=false`): Phase 1 deploys 3 analysis agents as standalone sub-agents in a single message with multiple `Task` calls. No team coordination; each sub-agent writes its assigned `analysis-*.md`. Orchestrator validates, persists, and generates the plan. Phase 2 deploys 3 validation sub-agents the same way. No inter-agent sharing.
- With `--team` (`AGENT_TEAM_MODE=true`): create team `pp-[feature-name]`, register analysis tasks, spawn 3 analysis teammates under the team, validate, generate plan, register validation tasks, spawn 3 validation teammates, review, then `close the agent group`. Teammates share findings via `send follow-up instructions`.

## Next Steps

Remove --dry-run flag to create the plan.
```

If `AGENT_TEAM_MODE=true`, additionally print the team roster block:

```
Team name:      pp-<sanitized-feature-name>
Teammates:      6 across 2 batches
  Batch 1 (analysis):
    - context-synthesizer    subagent_type=codebase-research-analyst  task=Condense planning docs
    - code-analyzer          subagent_type=codebase-research-analyst  task=Extract code patterns
    - task-structurer        subagent_type=codebase-research-analyst  task=Suggest task breakdown
  Batch 2 (validation):
    - path-validator         subagent_type=explore                     task=Verify file paths exist
    - dependency-validator   subagent_type=explore                     task=Check dependency graph
    - completeness-validator subagent_type=codebase-research-analyst   task=Ensure tasks actionable
```

Do **not** call `create an agent group`, `record the task`, `Agent`, `Task`, `send follow-up instructions`, or `close the agent group` in dry-run mode.

**STOP HERE** - do not write files or deploy agents.

---

## Phase 1: Analysis Stage

### Step 5: Team Setup (if `--team`)

If `AGENT_TEAM_MODE=false`, skip this step entirely — the default path dispatches standalone sub-agents in Step 8.

If `AGENT_TEAM_MODE=true`, follow the universal lifecycle contract at
`~/.codex/plugins/ycc/shared/references/agent-team-dispatch.md`.

Create an agent team for the planning workflow:

```
create an agent group: name="pp-[feature-name]", description="Planning team for [feature-name] parallel plan"
```

On failure, abort the skill with the `create an agent group` error message. Do NOT silently fall back to sub-agent mode.

### Step 6: Create Analysis Tasks (if `--team`)

If `AGENT_TEAM_MODE=false`, skip this step entirely — standalone `Task` dispatch does not use the shared task list.

If `AGENT_TEAM_MODE=true`, create 3 tasks in the shared task list:

1. **"Synthesize planning context for [feature-name]"** — Condense planning docs into actionable summary
2. **"Analyze code patterns for [feature-name]"** — Extract code patterns from relevant files
3. **"Suggest task structure for [feature-name]"** — Propose task breakdown and phases

If `record the task` fails for any task, call `close the agent group` and abort.

### Step 7: Read Analysis Prompt Templates

Read the analysis prompt templates:

```bash
cat ~/.codex/plugins/ycc/skills/parallel-plan/templates/analysis-prompts.md
```

### Step 8: Spawn Analysis Agents

| Name / Teammate `name` | Subagent Type               | Model  | Focus                  | Output File           |
| ---------------------- | --------------------------- | ------ | ---------------------- | --------------------- |
| `context-synthesizer`  | `codebase-research-analyst` | sonnet | Condense planning docs | `analysis-context.md` |
| `code-analyzer`        | `codebase-research-analyst` | sonnet | Extract code patterns  | `analysis-code.md`    |
| `task-structurer`      | `codebase-research-analyst` | sonnet | Suggest task breakdown | `analysis-tasks.md`   |

**Model Assignment**: Pass `model: "sonnet"` for all analysis agents.

Use the prompts from `analysis-prompts.md` with variables substituted:

- `{{FEATURE_NAME}}` - The feature directory name
- `{{FEATURE_DIR}}` - Full output directory path (`${feature_dir}`, resolved in Step 1)

**Why this is parallelized**: This prevents loading 50-100K+ tokens of raw files into main context. The analysis agents read everything and return 5-10K tokens of condensed, actionable analysis.

#### Path A — Standalone sub-agents (`AGENT_TEAM_MODE=false`, default)

**CRITICAL**: Deploy all 3 analysis agents in a **SINGLE message** with **MULTIPLE `Task` tool calls**. No `team_name` — standalone dispatch. Each `Task` call uses the `subagent_type` and `model` from the table above and the corresponding prompt from `analysis-prompts.md`.

In this mode there is no shared task list; rely on each `Task`'s return value plus the artifact checks in Steps 10–11 to confirm completion. Inter-agent `send follow-up instructions` coordination is not available — each sub-agent works independently from the prompt alone.

#### Path B — Agent team (`AGENT_TEAM_MODE=true`)

> **MANDATORY — AGENT TEAMS REQUIRED**
>
> In Path B you MUST follow the agent-team lifecycle at
> `~/.codex/plugins/ycc/shared/references/agent-team-dispatch.md`.
> Do NOT mix standalone `Task` calls with team dispatch.

All 3 `record the task` entries were registered up front in Step 6 — do not re-create them here.

Spawn all 3 teammates in **ONE message** with **THREE `Agent` tool calls**. Every call MUST include:

- `team_name = "pp-[feature-name]"`
- `name = "<teammate-name>"` (from the table above — must match the `record the task` subject prefix)
- `subagent_type` and `model` from the table above
- The analysis-specific prompt from `analysis-prompts.md`

After spawning, use `the task tracker` to confirm all 3 tasks are `completed` before proceeding to Step 10.

### Step 9: Monitor Analysis Progress

Wait for all 3 analysis agents to complete their work.

- **Path A (standalone, default)**: rely on `Task` return values; each sub-agent writes its `analysis-*.md` artifact before returning.
- **Path B (`--team`)**: use `the task tracker` to check progress. Teammates share findings with each other via `send follow-up instructions`. If a teammate gets stuck, send them guidance via `send follow-up instructions`.

When all 3 analysis tasks are complete, proceed to validation.

---

## Phase 2: Validate and Persist Analysis Artifacts

### Step 10: Validate Analysis Artifacts

After teammates complete, validate all analysis files:

```bash
~/.codex/plugins/ycc/skills/parallel-plan/scripts/validate-analysis-artifacts.sh "${feature_dir}"
```

If validation fails, message the relevant teammate to fix their output and retry.

### Step 11: Pre-Generation Gate (MANDATORY — cannot be skipped)

Run the pre-generation gate script:

```bash
~/.codex/plugins/ycc/skills/parallel-plan/scripts/persist-or-fail.sh "${feature_dir}"
```

- **Exit 0** → proceed to Phase 3
- **Exit 1** → the script prints `MISSING_FILES` and `ACTION_REQUIRED`. Message the failing teammate to re-write, then re-run this gate until it passes (exit 0)

**Do NOT proceed to plan generation until `persist-or-fail.sh` exits 0.**

### Step 12: Shut Down Analysis Teammates (if `--team`)

If `AGENT_TEAM_MODE=false`, skip this step — standalone sub-agents return on their own.

Otherwise, send shutdown requests to all analysis teammates:

```
send follow-up instructions to each teammate: a shutdown request
```

---

## Phase 3: Read Analysis

### Step 13: Read Condensed Analysis Files

After verifying all files exist, read only the condensed analysis outputs:

1. `${feature_dir}/analysis-context.md` - Planning context synthesis
2. `${feature_dir}/analysis-code.md` - Code pattern analysis
3. `${feature_dir}/analysis-tasks.md` - Task structure suggestions

These files contain 60-80% compressed insights versus reading all source files directly.

---

## Phase 4: Plan Generation

### Step 14: Generate Implementation Plan

Read the plan template structure:

```bash
cat ~/.codex/plugins/ycc/skills/parallel-plan/templates/plan-structure.md
```

Create `${feature_dir}/parallel-plan.md` following the template exactly:

#### Required Sections

**Title & Overview**

- Feature name as title
- 3-4 sentence information-dense breakdown
- Explain what needs to be done and why

**Critically Relevant Files and Documentation**

```markdown
## Critically Relevant Files and Documentation

- /path/to/file: Brief description of relevance
- /path/to/doc: When to reference this
```

**Implementation Plan**

```markdown
## Implementation Plan

### Phase 1: [Phase Name]

#### Task 1.1: [Task Title] Depends on [none]

**READ THESE BEFORE TASK**

- /file/path
- /doc/path

**Instructions**

Files to Create

- /file/path

Files to Modify

- /file/path

[Concise instructions on implementation]
```

**Advice Section**

```markdown
## Advice

- Insight that emerged from seeing the full picture
- Cross-cutting concerns and gotchas
- Specific warnings about code dependencies
```

### Step 15: Task Breakdown Guidelines

For each task ensure:

**Task Granularity**

- Completable in single focused session
- Modifies 1-3 files maximum
- Clear, actionable instructions

**Dependencies**

- Use `Depends on [none]` for independent tasks (maximize parallelism)
- Use `Depends on [1.1, 2.3]` for tasks requiring prior work
- Avoid long dependency chains (prefer wide over deep)
- Each phase should have at least one independent task

**File References**

- Use relative paths from project root
- Include line numbers for specific code references
- Group related files together
- Link to documentation files for context

---

## Phase 5: Validation Stage

### Step 16: Create Validation Tasks (if `--team`)

If `AGENT_TEAM_MODE=false`, skip this step entirely — standalone `Task` dispatch does not use the shared task list.

If `AGENT_TEAM_MODE=true`, create 3 validation tasks in the shared task list:

1. **"Validate file paths in [feature-name] plan"** — Verify all referenced files exist
2. **"Validate dependency graph in [feature-name] plan"** — Check for circular/invalid dependencies
3. **"Validate task completeness in [feature-name] plan"** — Ensure tasks are actionable

### Step 17: Read Validation Prompts

```bash
cat ~/.codex/plugins/ycc/skills/parallel-plan/templates/validation-prompts.md
```

### Step 18: Spawn Validation Agents

| Name / Teammate `name`   | Subagent Type               | Model  | Focus                                   |
| ------------------------ | --------------------------- | ------ | --------------------------------------- |
| `path-validator`         | `explore`                   | haiku  | Verify all referenced files exist       |
| `dependency-validator`   | `explore`                   | haiku  | Check for circular/invalid dependencies |
| `completeness-validator` | `codebase-research-analyst` | sonnet | Ensure tasks are actionable             |

**Model Assignment**: Pass `model: "haiku"` for path-validator and dependency-validator, `model: "sonnet"` for completeness-validator.

#### Path A — Standalone sub-agents (`AGENT_TEAM_MODE=false`, default)

**CRITICAL**: Deploy all 3 validation agents in a **SINGLE message** with **MULTIPLE `Task` tool calls**. No `team_name`. Each `Task` call uses the `subagent_type` and `model` from the table above and the corresponding prompt from `validation-prompts.md`. Rely on each `Task`'s return value for validator findings.

#### Path B — Agent team (`AGENT_TEAM_MODE=true`)

Spawn all 3 validation teammates in **ONE message** with **THREE `Agent` tool calls** and the matching `name=` from the table above. The 3 validation tasks registered in Step 16 are used here.

After spawning, use `the task tracker` to confirm all 3 tasks are `completed`.

### Step 19: Review Validation Results

After validators complete:

- **Path A (standalone, default)**: review each `Task` return value for validator findings.
- **Path B (`--team`)**: review findings from each validator (check their messages and task completions).
- Fix any issues identified:
  - Correct invalid file paths
  - Resolve circular dependencies
  - Add missing details to incomplete tasks
- Re-run validation if significant changes made.

### Step 20: Shut Down Validation Teammates (if `--team`)

If `AGENT_TEAM_MODE=false`, skip this step — standalone sub-agents return on their own.

Otherwise, send shutdown requests to all validation teammates.

---

## Phase 6: Output & Summary

### Step 21: Validate Plan Structure

Run the validation script:

```bash
~/.codex/plugins/ycc/skills/parallel-plan/scripts/validate-parallel-plan.sh "${feature_dir}/parallel-plan.md"
```

Report any structural issues found.

### Step 22: Clean Up Team (if `--team`)

If `AGENT_TEAM_MODE=false`, skip this step — there is no team to tear down.

Otherwise, delete the team and its resources:

```
close the agent group
```

### Step 23: Display Summary

Provide completion summary:

```markdown
# Parallel Plan Created

## Location

${feature_dir}/parallel-plan.md

## Analysis Files Generated

- ${feature_dir}/analysis-context.md (Planning context synthesis)
- ${feature_dir}/analysis-code.md (Code pattern analysis)
- ${feature_dir}/analysis-tasks.md (Task structure suggestions)

## Dispatch Summary

- Mode: [standalone sub-agents | agent team pp-[feature-name]]
- Phase 1: 3 analysis agents [standalone via Task | teammates that shared findings]
- Phase 2: 3 validation agents [standalone via Task | teammates that cross-checked each other]

## Plan Overview

- **Total Phases**: [count]
- **Total Tasks**: [count]
- **Independent Tasks**: [count that can run in parallel]
- **Max Dependency Depth**: [deepest chain]

## Task Breakdown by Phase

Phase 1: [count] tasks ([X] independent)
Phase 2: [count] tasks ([X] independent)
...

## Validation Results

- File Path Validation: [summary]
- Dependency Graph: [summary]
- Task Completeness: [summary]

## Context Efficiency

- Analysis agents condensed context from ~50-100K tokens to ~5-10K tokens
- Main context preserved for plan generation and validation

## Next Steps (FOR USER - NOT FOR THIS SKILL)

**THIS SKILL IS NOW COMPLETE. DO NOT PROCEED.**

The user can manually run the implementation when ready:

/implement-plan [feature-name]

Review steps for user:

1. Review the plan: ${feature_dir}/parallel-plan.md
2. Review analysis files for detailed insights (optional)
3. Refine tasks if needed
```

---

**STOP**: Do not execute implement-plan. Do not write any more files. Do not modify any code. This skill is complete.

---

## Quality Standards

### Task Quality Checklist

Each task must have:

- [ ] Clear, descriptive title
- [ ] Explicit dependencies listed
- [ ] "READ THESE BEFORE TASK" section with relevant files
- [ ] Files to Create list (if any)
- [ ] Files to Modify list
- [ ] Concise, actionable instructions
- [ ] Gotchas and warnings documented

### Plan Quality Checklist

The overall plan must have:

- [ ] Information-dense overview (3-4 sentences)
- [ ] Complete list of critically relevant files
- [ ] Tasks organized into logical phases
- [ ] At least one independent task per phase
- [ ] Advice section with implementation insights
- [ ] No circular dependencies
- [ ] All file paths verified

---

## CRITICAL CONSTRAINTS

- **PLANNING ONLY** - This skill creates documentation, never implementation
- **NO CODE CHANGES** - Do not modify any application source files
- **NO IMPLEMENTATION** - Do not execute tasks from the plan you create
- **STOP AFTER SUMMARY** - After displaying the completion summary, stop completely
- **DO NOT CHAIN** - Do not automatically proceed to implement-plan
- **PERSIST ARTIFACTS** - All 3 analysis files must exist before plan generation
- **CLEAN UP TEAM (Path B only)** - Always `close the agent group` before completing when a team was created

## Output Contract

All files are written to `${feature_dir}/` (resolved via `resolve-plans-dir.sh`).

| File                  | Producer                     | Required Before             |
| --------------------- | ---------------------------- | --------------------------- |
| `analysis-context.md` | context-synthesizer teammate | parallel-plan.md generation |
| `analysis-code.md`    | code-analyzer teammate       | parallel-plan.md generation |
| `analysis-tasks.md`   | task-structurer teammate     | parallel-plan.md generation |
| `parallel-plan.md`    | Team lead (this skill)       | Skill completion            |

**Contract Rules**:

1. Each analysis agent MUST write its own output file using the Write tool
2. In Path B (`--team`), each teammate MUST share key findings with relevant teammates via send follow-up instructions. In Path A (standalone), inter-agent sharing is unavailable — each sub-agent works independently.
3. The orchestrator MUST run `validate-analysis-artifacts.sh` after agents complete (Step 10)
4. The orchestrator MUST run `persist-or-fail.sh` as a mandatory pre-generation gate (Step 11)
5. If validation fails, the orchestrator MUST message the failing teammate (Path B) or re-dispatch the sub-agent (Path A) to fix their output
6. No file may be skipped or deferred — `persist-or-fail.sh` must exit 0 before plan generation
7. In Path B, the team MUST be cleaned up (close the agent group) before skill completion

## Monorepo Support

Always resolve plans via `resolve-plans-dir.sh`.

Default:

- Plans at repo-root `docs/plans/`

Optional local scope via `.plans-config`:

```yaml
plans_dir: docs/plans
scope: local
```

## Important Notes

- **You are the planning orchestrator** - coordinate analysis and validation stages
- **Choose dispatch mode from `$ARGUMENTS`** - default is standalone sub-agents via `Task`; `--team` switches to teammates under `create an agent group`/`the task tracker`
- **Team setup first (Path B only)** - call `create an agent group` and register analysis tasks before spawning teammates
- **Spawn in parallel** - a single message with multiple `Task` calls (Path A) or multiple `Agent` calls with `name=` + `name=` (Path B)
- **Pass model parameters** - use `model: "sonnet"` for analysis agents, `model: "haiku"` for path/dependency validators, `model: "sonnet"` for completeness-validator
- **Teammates share findings (Path B only)** - inter-teammate `send follow-up instructions` coordination is unavailable to standalone sub-agents
- **Two stages** - analysis first, then validation
- **Shut down between stages (Path B only)** - shut down analysis teammates before spawning validators
- **Validate with scripts** - run validation scripts after agents complete
- **Message on failure (Path B)** - if validation fails, message the relevant teammate; in Path A, re-dispatch a sub-agent
- **Preserve main context** - read condensed analysis files (~5-10K tokens) instead of raw source files (~50-100K+ tokens)
- **Maximize parallelism** - prefer independent tasks over sequential chains
- **Be specific** - include exact file paths and clear instructions
- **Quality over speed** - a well-structured plan saves time during implementation
- **Clean up team (Path B only)** - always `close the agent group` before completing when a team was created
- **Monorepo aware** - automatically resolves correct plans directory
