---
name: parallel-plan
description: Create detailed parallel implementation plans by orchestrating analysis agents and validation, then synthesizing dependency-aware tasks into parallel-plan.md. Use after shared-context to prepare implementation-ready planning artifacts.
argument-hint: '[feature-name] [--dry-run]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Task
  - TodoWrite
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/scripts/*.sh:*)'
  - 'Bash(${CLAUDE_PLUGIN_ROOT}/scripts/*.sh:*)'
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

Create `parallel-plan.md` by orchestrating parallel analysis agents, synthesizing implementation tasks, and validating plan quality.

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
source ${CLAUDE_PLUGIN_ROOT}/scripts/resolve-plans-dir.sh
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

## Analysis Agents That Would Run (Phase 1)

1. Context Synthesizer - Condense planning documentation
2. Code Analyzer - Extract code patterns from relevant files
3. Task Structure Agent - Suggest task breakdown and phases

## Files That Would Be Created

- ${PLANS_DIR}/[feature-name]/analysis-context.md (by Context Synthesizer)
- ${PLANS_DIR}/[feature-name]/analysis-code.md (by Code Analyzer)
- ${PLANS_DIR}/[feature-name]/analysis-tasks.md (by Task Structure Agent)
- ${PLANS_DIR}/[feature-name]/parallel-plan.md (final plan)

## Validation Agents That Would Run (Phase 5)

1. File Path Validator - Verify all paths exist
2. Dependency Validator - Check dependency graph
3. Task Completeness Validator - Ensure tasks are actionable

## Execution Model

- Deploy analysis agents in parallel
- Persist analysis artifacts
- Generate plan from condensed analysis
- Validate with parallel validation agents
- Fix issues and finalize

## Next Steps

Remove --dry-run flag to create the plan.
```

**STOP HERE** - do not write files or deploy agents.

---

## Phase 1: Agent-Based Context Analysis

### Step 5: Read Analysis Prompt Templates

Read the analysis prompt templates:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/templates/analysis-prompts.md
```

This provides prompts for 3 parallel analysis agents that will condense planning context.

### Step 6: Deploy Analysis Agents

**CRITICAL**: Deploy all 3 agents in a **SINGLE message** with **MULTIPLE Task tool calls**.

Each agent MUST write its findings to the specified output file. The orchestrator MUST verify file persistence after agents complete.

| Agent                | Subagent Type               | Focus                  | Output File           |
| -------------------- | --------------------------- | ---------------------- | --------------------- |
| Context Synthesizer  | `codebase-research-analyst` | Condense planning docs | `analysis-context.md` |
| Code Analyzer        | `codebase-research-analyst` | Extract code patterns  | `analysis-code.md`    |
| Task Structure Agent | `codebase-research-analyst` | Suggest task breakdown | `analysis-tasks.md`   |

Use the prompts from `analysis-prompts.md` with variables substituted:

- `{{FEATURE_NAME}}` - The feature directory name
- `{{FEATURE_DIR}}` - Full output directory path (`${feature_dir}`, resolved in Step 1)

Each agent will:

- Read relevant source files (planning docs, code files, codebase structure)
- Extract actionable insights
- Write condensed analysis to `${feature_dir}/[output-file]`

**Why use agents**: This prevents loading 50-100K+ tokens of raw files into main context. Agents read everything and return 5-10K tokens of condensed, actionable analysis.

---

## Phase 2: Validate and Persist Analysis Artifacts

### Step 7: First Validation Check

After agents complete, validate all analysis files:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/scripts/validate-analysis-artifacts.sh "${feature_dir}"
```

If validation passes, proceed to Step 7a (mandatory persistence check).
If validation fails, proceed to Step 8.

### Step 7a: Mandatory Agent Response Persistence

To avoid any agent-level write tool variance, persist all analysis output directly from agent responses:

1. For each deployed analysis agent response, extract its assigned tag:
   - `<ANALYSIS_CONTEXT>...</ANALYSIS_CONTEXT>` from Agent 1
   - `<ANALYSIS_CODE>...</ANALYSIS_CODE>` from Agent 2
   - `<ANALYSIS_TASKS>...</ANALYSIS_TASKS>` from Agent 3
2. Write each extracted body to the target file using the Write tool, even if the file already exists:
   - `${feature_dir}/analysis-context.md`
   - `${feature_dir}/analysis-code.md`
   - `${feature_dir}/analysis-tasks.md`
3. Immediately re-run `validate-analysis-artifacts.sh` after writing to ensure all files are present.
4. If validation succeeds after writing, proceed to Step 9.
5. If validation still fails, proceed to Step 8.

If a required tag is missing in a response, re-deploy ONLY that specific agent with its original prompt and re-run this step.

### Step 8: Fallback Write (only if Step 7 or Step 7a failed)

For each missing file reported by the validation script:

1. Find the corresponding `<ANALYSIS_*>` tag content from the agent's response:
   - Missing `analysis-context.md` → look for `<ANALYSIS_CONTEXT>...</ANALYSIS_CONTEXT>` in Agent 1's response
   - Missing `analysis-code.md` → look for `<ANALYSIS_CODE>...</ANALYSIS_CODE>` in Agent 2's response
   - Missing `analysis-tasks.md` → look for `<ANALYSIS_TASKS>...</ANALYSIS_TASKS>` in Agent 3's response
2. Write the tagged content to `${feature_dir}/[filename]` using the Write tool
3. If no tagged content is available for a missing file, re-deploy ONLY that specific agent with its original prompt

After writing fallback files, re-run validation:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/scripts/validate-analysis-artifacts.sh "${feature_dir}"
```

If validation still fails after re-deployment, stop and report what is missing.

### Step 9: Pre-Generation Gate (MANDATORY — cannot be skipped)

Run the pre-generation gate script:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/scripts/persist-or-fail.sh "${feature_dir}"
```

- **Exit 0** → proceed to Phase 3
- **Exit 1** → the script prints `MISSING_FILES` and `ACTION_REQUIRED`. Write the missing files NOW (from response tags or by re-deploying agents), then re-run this gate until it passes (exit 0)

- **Do not** attempt to generate `parallel-plan.md` if Step 7, 7a, or Step 8 have not passed.

**Do NOT proceed to plan generation until `persist-or-fail.sh` exits 0.**

---

## Phase 3: Read Analysis

### Step 10: Read Condensed Analysis Files

After verifying all files exist, read only the condensed analysis outputs:

1. `${feature_dir}/analysis-context.md` - Planning context synthesis
2. `${feature_dir}/analysis-code.md` - Code pattern analysis
3. `${feature_dir}/analysis-tasks.md` - Task structure suggestions

These files contain 60-80% compressed insights versus reading all source files directly.

---

## Phase 4: Plan Generation

### Step 11: Create Task List

Using **TodoWrite**, create a comprehensive task list with:

- Each major task from the plan
- Task dependencies tracked
- In_progress status for current work

### Step 12: Generate Implementation Plan

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

### Step 13: Task Breakdown Guidelines

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

## Phase 5: Validation (Parallel Agents)

### Step 14: Deploy Validation Agents

Read the validation prompts:

```bash
cat ${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/templates/validation-prompts.md
```

**CRITICAL**: Deploy all 3 agents in a **SINGLE message** with **MULTIPLE Task tool calls**.

| Agent                       | Subagent Type               | Focus                                   |
| --------------------------- | --------------------------- | --------------------------------------- |
| File Path Validator         | `explore`                   | Verify all referenced files exist       |
| Dependency Validator        | `explore`                   | Check for circular/invalid dependencies |
| Task Completeness Validator | `codebase-research-analyst` | Ensure tasks are actionable             |

Use the prompts from `validation-prompts.md` with the feature name substituted.

### Step 15: Review Validation Results

After agents complete:

- Review findings from each validator
- Fix any issues identified:
  - Correct invalid file paths
  - Resolve circular dependencies
  - Add missing details to incomplete tasks
- Re-run validation if significant changes made

---

## Phase 6: Output & Summary

### Step 16: Validate Plan Structure

Run the validation script:

```bash
${CLAUDE_PLUGIN_ROOT}/skills/parallel-plan/scripts/validate-parallel-plan.sh "${feature_dir}/parallel-plan.md"
```

Report any structural issues found.

### Step 17: Display Summary

Provide completion summary:

```markdown
# Parallel Plan Created

## Location

${feature_dir}/parallel-plan.md

## Analysis Files Generated

- ${feature_dir}/analysis-context.md (Planning context synthesis)
- ${feature_dir}/analysis-code.md (Code pattern analysis)
- ${feature_dir}/analysis-tasks.md (Task structure suggestions)

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

## Output Contract

All files are written to `${feature_dir}/` (resolved via `resolve-plans-dir.sh`).

| File                  | Producer                  | Required Before             |
| --------------------- | ------------------------- | --------------------------- |
| `analysis-context.md` | Context Synthesizer agent | parallel-plan.md generation |
| `analysis-code.md`    | Code Analyzer agent       | parallel-plan.md generation |
| `analysis-tasks.md`   | Task Structure Agent      | parallel-plan.md generation |
| `parallel-plan.md`    | Orchestrator (this skill) | Skill completion            |

**Contract Rules**:

1. Each agent MUST write its own output file using the Write tool AND include content in its assigned `<ANALYSIS_*>` response tag
2. The orchestrator MUST run `validate-analysis-artifacts.sh` after agents complete (Step 7)
3. The orchestrator MUST persist all analysis outputs from `<ANALYSIS_*>` response tags with the Write tool (Step 7a)
4. If validation still fails after persistence, the orchestrator MUST write/repair missing files from `<ANALYSIS_*>` response tags or re-deploy failed agents (Step 8)
5. The orchestrator MUST run `persist-or-fail.sh` as a mandatory pre-generation gate (Step 9)
6. No file may be skipped or deferred — `persist-or-fail.sh` must exit 0 before plan generation

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

- **You are the planner** - break down the feature systematically
- **Use agents for context gathering** - deploy analysis agents to condense large amounts of information
- **Validate with script** - run `validate-analysis-artifacts.sh` after agents complete
- **Re-deploy on failure** - if validation fails, re-deploy only the failed agents
- **Preserve main context** - read condensed analysis files (~5-10K tokens) instead of raw source files (~50-100K+ tokens)
- **Maximize parallelism** - prefer independent tasks over sequential chains
- **Be specific** - include exact file paths and clear instructions
- **Validate thoroughly** - use all three validation agents
- **Quality over speed** - a well-structured plan saves time during implementation
- **Monorepo aware** - automatically resolves correct plans directory
