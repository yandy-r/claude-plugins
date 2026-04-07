---
name: parallel-plan
description: Create detailed parallel implementation plans by orchestrating analysis and validation agent teams, then synthesizing dependency-aware tasks into parallel-plan.md. Use after shared-context to prepare implementation-ready planning artifacts.
argument-hint: '[feature-name] [--dry-run]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Agent
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
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/scripts/*.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/*.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/**/*.sh:*)'
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

Create `parallel-plan.md` by orchestrating analysis and validation agent teams, synthesizing implementation tasks, and validating plan quality.

## Workflow Integration

```text
shared-context (step 1) -> parallel-plan (this skill) -> implement-plan (step 3)
```

This skill requires `${feature_dir}/shared.md` and ends after producing analysis artifacts and `parallel-plan.md`.

**BOUNDARY**: This skill ENDS after creating `parallel-plan.md`. The user manually runs `/implement-plan` when ready.

**If shared.md doesn't exist**, run `/shared-context [feature-name]` first.

## Arguments

**Target**: `$ARGUMENTS`

Parse arguments:

- **feature-name**: The name of the feature to plan (matches directory name in `${PLANS_DIR}`)
- **--dry-run**: Show what would be created without making changes

If no feature name provided, abort with usage instructions.

---

## Phase 0: Prerequisites and Dry Run Check

### Step 1: Resolve Plans Directory

Use the shared resolver to determine the correct plans directory:

```bash
source ${CLAUDE_PLUGIN_ROOT}/skills/_shared/scripts/resolve-plans-dir.sh
feature_dir="$(get_feature_plan_dir "[feature-name]")"
```

### Step 2: Validate Prerequisites

Extract the feature name from `$ARGUMENTS` (first non-flag argument).

Run the prerequisites check script:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/scripts/check-prerequisites.sh [feature-name]
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

## Team: pp-[feature-name]

### Phase 1: Analysis Teammates (3 agents)

1. context-synthesizer - Condense planning documentation
2. code-analyzer - Extract code patterns from relevant files
3. task-structurer - Suggest task breakdown and phases

### Phase 2: Validation Teammates (3 agents)

1. path-validator - Verify all paths exist
2. dependency-validator - Check dependency graph
3. completeness-validator - Ensure tasks are actionable

## Files That Would Be Created

- ${PLANS_DIR}/[feature-name]/analysis-context.md (by context-synthesizer)
- ${PLANS_DIR}/[feature-name]/analysis-code.md (by code-analyzer)
- ${PLANS_DIR}/[feature-name]/analysis-tasks.md (by task-structurer)
- ${PLANS_DIR}/[feature-name]/parallel-plan.md (final plan)

## Execution Model

- Create agent team with analysis teammates (Phase 1)
- Teammates share findings and cross-reference
- Validate analysis artifacts
- Generate plan from condensed analysis
- Spawn validation teammates (Phase 2)
- Fix issues and finalize
- Team cleanup

## Next Steps

Remove --dry-run flag to create the plan.
```

**STOP HERE** - do not write files or deploy agents.

---

## Phase 1: Analysis Team

### Step 5: Create the Team

Create an agent team for the planning workflow:

```
TeamCreate: team_name="pp-[feature-name]", description="Planning team for [feature-name] parallel plan"
```

### Step 6: Create Analysis Tasks

Create 3 tasks in the shared task list:

1. **"Synthesize planning context for [feature-name]"** — Condense planning docs into actionable summary
2. **"Analyze code patterns for [feature-name]"** — Extract code patterns from relevant files
3. **"Suggest task structure for [feature-name]"** — Propose task breakdown and phases

### Step 7: Read Analysis Prompt Templates

Read the analysis prompt templates:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/templates/analysis-prompts.md
```

### Step 8: Spawn Analysis Teammates

**CRITICAL**: Spawn all 3 teammates in a **SINGLE message** with **MULTIPLE Agent tool calls**, each with `team_name="pp-[feature-name]"`.

| Teammate Name         | Subagent Type               | Model  | Focus                  | Output File           |
| --------------------- | --------------------------- | ------ | ---------------------- | --------------------- |
| `context-synthesizer` | `codebase-research-analyst` | sonnet | Condense planning docs | `analysis-context.md` |
| `code-analyzer`       | `codebase-research-analyst` | sonnet | Extract code patterns  | `analysis-code.md`    |
| `task-structurer`     | `codebase-research-analyst` | sonnet | Suggest task breakdown | `analysis-tasks.md`   |

**Model Assignment**: Pass `model: "sonnet"` for all analysis teammates.

Use the prompts from `analysis-prompts.md` with variables substituted:

- `{{FEATURE_NAME}}` - The feature directory name
- `{{FEATURE_DIR}}` - Full output directory path (`${feature_dir}`, resolved in Step 1)

**Why use teammates**: This prevents loading 50-100K+ tokens of raw files into main context. Teammates read everything and return 5-10K tokens of condensed, actionable analysis.

### Step 9: Monitor Analysis Progress

Wait for teammates to complete. Use `TaskList` to check progress. When all 3 analysis tasks are complete, proceed to validation.

---

## Phase 2: Validate and Persist Analysis Artifacts

### Step 10: Validate Analysis Artifacts

After teammates complete, validate all analysis files:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/scripts/validate-analysis-artifacts.sh "${feature_dir}"
```

If validation fails, message the relevant teammate to fix their output and retry.

### Step 11: Pre-Generation Gate (MANDATORY — cannot be skipped)

Run the pre-generation gate script:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/scripts/persist-or-fail.sh "${feature_dir}"
```

- **Exit 0** → proceed to Phase 3
- **Exit 1** → the script prints `MISSING_FILES` and `ACTION_REQUIRED`. Message the failing teammate to re-write, then re-run this gate until it passes (exit 0)

**Do NOT proceed to plan generation until `persist-or-fail.sh` exits 0.**

### Step 12: Shut Down Analysis Teammates

Send shutdown requests to all analysis teammates:

```
SendMessage to each teammate: message={type: "shutdown_request"}
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
cat ${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/templates/plan-structure.md
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

## Phase 5: Validation Team

### Step 16: Create Validation Tasks

Create 3 validation tasks in the shared task list:

1. **"Validate file paths in [feature-name] plan"** — Verify all referenced files exist
2. **"Validate dependency graph in [feature-name] plan"** — Check for circular/invalid dependencies
3. **"Validate task completeness in [feature-name] plan"** — Ensure tasks are actionable

### Step 17: Read Validation Prompts

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/templates/validation-prompts.md
```

### Step 18: Spawn Validation Teammates

**CRITICAL**: Spawn all 3 validation teammates in a **SINGLE message** with **MULTIPLE Agent tool calls**, each with `team_name="pp-[feature-name]"`.

| Teammate Name            | Subagent Type               | Model  | Focus                                   |
| ------------------------ | --------------------------- | ------ | --------------------------------------- |
| `path-validator`         | `explore`                   | haiku  | Verify all referenced files exist       |
| `dependency-validator`   | `explore`                   | haiku  | Check for circular/invalid dependencies |
| `completeness-validator` | `codebase-research-analyst` | sonnet | Ensure tasks are actionable             |

**Model Assignment**: Pass `model: "haiku"` for path-validator and dependency-validator, `model: "sonnet"` for completeness-validator.

### Step 19: Review Validation Results

After validators complete:

- Review findings from each validator (check their messages and task completions)
- Fix any issues identified:
  - Correct invalid file paths
  - Resolve circular dependencies
  - Add missing details to incomplete tasks
- Re-run validation if significant changes made

### Step 20: Shut Down Validation Teammates

Send shutdown requests to all validation teammates.

---

## Phase 6: Output & Summary

### Step 21: Validate Plan Structure

Run the validation script:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/scripts/validate-parallel-plan.sh "${feature_dir}/parallel-plan.md"
```

Report any structural issues found.

### Step 22: Clean Up Team

Delete the team and its resources:

```
TeamDelete
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

## Team Summary

- Team: pp-[feature-name]
- Phase 1: 3 analysis teammates (shared findings with each other)
- Phase 2: 3 validation teammates (cross-checked each other)

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

- Analysis teammates condensed context from ~50-100K tokens to ~5-10K tokens
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
- **CLEAN UP TEAM** - Always delete the team before completing

## Output Contract

All files are written to `${feature_dir}/` (resolved via `resolve-plans-dir.sh`).

| File                  | Producer                     | Required Before             |
| --------------------- | ---------------------------- | --------------------------- |
| `analysis-context.md` | context-synthesizer teammate | parallel-plan.md generation |
| `analysis-code.md`    | code-analyzer teammate       | parallel-plan.md generation |
| `analysis-tasks.md`   | task-structurer teammate     | parallel-plan.md generation |
| `parallel-plan.md`    | Team lead (this skill)       | Skill completion            |

**Contract Rules**:

1. Each teammate MUST write its own output file using the Write tool
2. Each teammate MUST share key findings with relevant teammates via SendMessage
3. The team lead MUST run `validate-analysis-artifacts.sh` after teammates complete (Step 10)
4. The team lead MUST run `persist-or-fail.sh` as a mandatory pre-generation gate (Step 11)
5. If validation fails, the team lead MUST message the failing teammate to fix their output
6. No file may be skipped or deferred — `persist-or-fail.sh` must exit 0 before plan generation
7. The team MUST be cleaned up (TeamDelete) before skill completion

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

- **You are the team lead** - coordinate analysis and validation teams
- **Create team first** - use TeamCreate before spawning teammates
- **Spawn teammates in parallel** - single message with multiple Agent calls
- **Pass model parameters** - use `model: "sonnet"` for analysis agents, `model: "haiku"` for path/dependency validators, `model: "sonnet"` for completeness-validator
- **Teammates share findings** - they communicate with each other via SendMessage
- **Two phases** - analysis teammates first, then validation teammates
- **Shut down between phases** - shut down analysis teammates before spawning validators
- **Validate with scripts** - run validation scripts after teammates complete
- **Message on failure** - if validation fails, message the relevant teammate
- **Preserve main context** - read condensed analysis files (~5-10K tokens) instead of raw source files (~50-100K+ tokens)
- **Maximize parallelism** - prefer independent tasks over sequential chains
- **Be specific** - include exact file paths and clear instructions
- **Quality over speed** - a well-structured plan saves time during implementation
- **Clean up team** - always TeamDelete before completing
- **Monorepo aware** - automatically resolves correct plans directory
