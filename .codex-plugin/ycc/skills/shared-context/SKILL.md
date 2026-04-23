---
name: shared-context
description: Create shared context documentation for a feature by deploying 4 researchers
  (architecture, patterns, integration, docs) that write research artifacts, then
  synthesizing verified findings into shared.md. Use as Step 1 before parallel-plan
  when preparing implementation context. Default is standalone parallel sub-agents
  via the parallel agent workflow. Pass `--team` (Codex runtime only; not available
  in bundle invocations) to deploy the 4 researchers as teammates under a shared create
  an agent group/the task tracker with coordinated shutdown.
---

## SCOPE LIMITATION - READ FIRST

**THIS SKILL ONLY CREATES RESEARCH CONTEXT FILES. IT NEVER PLANS OR IMPLEMENTS.**

- DO NOT run the parallel-plan skill
- DO NOT run the implement-plan skill
- DO NOT execute implementation tasks
- DO NOT modify application source files

**Outputs**:

- `${PLANS_DIR}/[feature-name]/research-architecture.md`
- `${PLANS_DIR}/[feature-name]/research-patterns.md`
- `${PLANS_DIR}/[feature-name]/research-integration.md`
- `${PLANS_DIR}/[feature-name]/research-docs.md`
- `${PLANS_DIR}/[feature-name]/shared.md`

After creating the shared context files and displaying the summary, **STOP COMPLETELY**.

---

# Shared Context Creator

Create planning context for a feature by dispatching 4 researchers in parallel — standalone sub-agents by default, or an agent team with `--team` (Codex runtime only; not available in bundle invocations) where teammates share findings with each other — then persisting workstream reports and synthesizing `shared.md`.

## Workflow Integration

```text
shared-context (this skill) -> parallel-plan -> implement-plan
```

This skill ends after research files and `shared.md` are created and validated.

## Arguments

**Target**: `$ARGUMENTS`

Parse arguments (flags first, then the feature name):

- **--team**: Optional. (Codex runtime only; not available in bundle invocations) Deploy the 4 researchers as teammates under a shared `create an agent group`/`the task tracker` with coordinated shutdown. Default is standalone parallel sub-agents via the `Task` tool. Cursor and Codex bundles lack team tools — do not pass `--team` there.
- **--dry-run**: Show orchestration plan without creating files. With `--team`, also prints the team name and 4-teammate roster.
- **feature-name**: Required. Directory name under `${PLANS_DIR}`.

If no feature name provided, abort with usage instructions:

```
Usage: /shared-context [--team] [feature-name] [--dry-run]

Examples:
  /shared-context user-authentication
  /shared-context payment-integration --dry-run
  /shared-context --team payment-integration
  /shared-context --team --dry-run user-authentication
```

---

## Phase 0: Initialize Planning Directory

### Step 1: Parse Arguments

Extract from `$ARGUMENTS`:

1. **--team**: Boolean flag. Set `AGENT_TEAM_MODE=true` if present, else `false`.
2. **--dry-run**: Boolean flag. Set `DRY_RUN=true` if present, else `false`.
3. **feature-name**: First non-flag argument (required).

Validate the feature name:

- Must be provided
- Should use kebab-case (lowercase with hyphens)
- No special characters except hyphens

**Compatibility note**: When this skill is invoked from a Cursor or Codex bundle, `--team` must not be used (those bundles ship without team tools).

### Step 2: Resolve Plans Directory

Use the shared resolver to determine the correct plans directory:

```bash
source ~/.codex/plugins/ycc/shared/scripts/resolve-plans-dir.sh
feature_dir="$(get_feature_plan_dir "[feature-name]")"
```

This handles monorepo detection, `.plans-config` files, and git root resolution automatically.

### Step 3: Ensure Feature Directory Exists

```bash
mkdir -p "$feature_dir"
```

### Step 4: Load Existing Planning Context

If the directory already has `.md` files:

- Read them for prior context
- Reuse findings where valid
- Avoid duplicating existing analysis

---

## Phase 1: Dry Run Check

### Step 5: Handle `--dry-run`

If `--dry-run` is present in `$ARGUMENTS`:

Display:

```markdown
# Dry Run: Shared Context for [feature-name]

## Directory

- ${PLANS_DIR}/[feature-name]/

## Research Pipeline

Dispatch Mode: [standalone sub-agents | agent team]
Researchers: 4 (architecture-researcher, patterns-researcher, integration-researcher, docs-researcher)

1. architecture-researcher - System structure and components
2. patterns-researcher - Existing patterns to follow
3. integration-researcher - APIs, databases, external systems
4. docs-researcher - Relevant docs and guides

## Files That Would Be Created

- ${PLANS_DIR}/[feature-name]/research-architecture.md
- ${PLANS_DIR}/[feature-name]/research-patterns.md
- ${PLANS_DIR}/[feature-name]/research-integration.md
- ${PLANS_DIR}/[feature-name]/research-docs.md
- ${PLANS_DIR}/[feature-name]/shared.md

## Execution Model

- Default (`AGENT_TEAM_MODE=false`): deploy 4 researchers as standalone sub-agents in a single message with multiple `Task` calls. No team coordination; each sub-agent writes its assigned `research-*.md`. Orchestrator validates and synthesizes `shared.md`.
- With `--team` (`AGENT_TEAM_MODE=true`): create team `sc-[feature-name]`, register 4 tasks, spawn 4 teammates with shared task state and inter-teammate `send follow-up instructions`, then shut down and `close the agent group` before synthesis.

## Next Steps

Remove --dry-run flag to execute research.
```

If `AGENT_TEAM_MODE=true`, additionally print the team roster block:

```
Team name:      sc-<sanitized-feature-name>
Teammates:      4
  - architecture-researcher   subagent_type=codebase-research-analyst   task=System structure, components, data flow
  - patterns-researcher       subagent_type=codebase-research-analyst   task=Existing patterns, conventions, examples
  - integration-researcher    subagent_type=codebase-research-analyst   task=APIs, databases, external systems
  - docs-researcher           subagent_type=codebase-research-analyst   task=Relevant documentation files
```

Do **not** call `create an agent group`, `record the task`, `Agent`, `Task`, `send follow-up instructions`, or `close the agent group` in dry-run mode.

**STOP HERE** - do not create files or deploy agents.

---

## Phase 2: Research Dispatch

### Step 6: Team Setup (if `--team`)

If `AGENT_TEAM_MODE=false`, skip this step entirely — the default path dispatches standalone sub-agents in Step 9.

If `AGENT_TEAM_MODE=true`, follow the universal lifecycle contract at
`~/.codex/plugins/ycc/shared/references/agent-team-dispatch.md`.

Create an agent team for the research phase:

```
create an agent group: team_name="sc-[feature-name]", description="Research team for [feature-name] shared context"
```

On failure, abort the skill with the `create an agent group` error message. Do NOT silently fall back to sub-agent mode.

### Step 7: Create Research Tasks (if `--team`)

If `AGENT_TEAM_MODE=false`, skip this step entirely — standalone `Task` dispatch does not use the shared task list.

If `AGENT_TEAM_MODE=true`, create 4 tasks in the shared task list — one per research domain:

1. **"Research architecture for [feature-name]"** — System structure, components, data flow, integration points
2. **"Research patterns for [feature-name]"** — Architectural patterns, code conventions, error handling, testing
3. **"Research integrations for [feature-name]"** — APIs, databases, external services, configuration
4. **"Research documentation for [feature-name]"** — Docs, READMEs, code comments, external references

If `record the task` fails for any task, call `close the agent group` and abort.

### Step 8: Read Research Prompts

Read the research prompts template:

```bash
cat ~/.codex/plugins/ycc/skills/shared-context/templates/research-prompts.md
```

### Step 9: Spawn Research Agents

| Teammate Name             | Subagent Type               | Output File                | Model  | Focus                                    |
| ------------------------- | --------------------------- | -------------------------- | ------ | ---------------------------------------- |
| `architecture-researcher` | `codebase-research-analyst` | `research-architecture.md` | sonnet | System structure, components, data flow  |
| `patterns-researcher`     | `codebase-research-analyst` | `research-patterns.md`     | sonnet | Existing patterns, conventions, examples |
| `integration-researcher`  | `codebase-research-analyst` | `research-integration.md`  | sonnet | APIs, databases, external systems        |
| `docs-researcher`         | `codebase-research-analyst` | `research-docs.md`         | sonnet | Relevant documentation files             |

**Model Assignment**: Pass `model: "sonnet"` for all shared-context researchers.

Each researcher writes findings to `${feature_dir}/[output-file]`.

Use the prompts from `research-prompts.md` with variables substituted:

- `{{FEATURE_NAME}}` - The feature directory name
- `{{FEATURE_DIR}}` - Full output directory path (`${feature_dir}`, resolved in Step 2)

#### Path A — Standalone sub-agents (`AGENT_TEAM_MODE=false`, default)

**CRITICAL**: Deploy all 4 researchers in a **SINGLE message** with **MULTIPLE `Task` tool calls**. No `team_name` — standalone dispatch. Each `Task` call uses the `subagent_type` and `model` from the table above and the corresponding prompt from `research-prompts.md`.

In this mode there is no shared task list; rely on each `Task`'s return value plus the artifact check in Step 11 to confirm completion. Inter-teammate `send follow-up instructions` coordination is not available — each sub-agent works independently from the prompt alone.

#### Path B — Agent team (`AGENT_TEAM_MODE=true`)

> **MANDATORY — AGENT TEAMS REQUIRED**
>
> In Path B you MUST follow the agent-team lifecycle at
> `~/.codex/plugins/ycc/shared/references/agent-team-dispatch.md`.
> Do NOT mix standalone `Task` calls with team dispatch.

All 4 `record the task` entries were registered up front in Step 7 — do not re-create them here.

Spawn all 4 teammates in **ONE message** with **FOUR `Agent` tool calls**. Every call MUST include:

- `team_name = "sc-[feature-name]"`
- `name = "<teammate-name>"` (from the table above — must match the `record the task` subject prefix)
- `subagent_type` and `model` from the table above
- The researcher-specific prompt from `research-prompts.md`

After spawning, use `the task tracker` to confirm all 4 tasks are `completed` before proceeding to Step 11. Do not rely on agent return values alone — check the shared task state.

### Step 10: Monitor Research Progress

Wait for all 4 researchers to complete their work.

- **Path A (standalone, default)**: rely on `Task` return values; each sub-agent writes its `research-*.md` artifact before returning.
- **Path B (`--team`)**: use `the task tracker` to check progress. Teammates will claim tasks from the shared list, share key findings with each other via `send follow-up instructions`, write their output file, and mark their task complete. If a teammate gets stuck, send them guidance via `send follow-up instructions`.

---

## Phase 3: Validate Research Artifacts

### Step 11: Validate Research Artifacts

After all teammates complete, validate all research files:

```bash
~/.codex/plugins/ycc/skills/shared-context/scripts/validate-research-artifacts.sh "${feature_dir}"
```

If validation fails: identify which files are missing or invalid from the script output, send a message to the relevant teammate asking them to fix their output, wait for correction, then rerun validation until pass.

**Do not proceed to synthesis until validation passes.**

### Step 12: Shut Down Research Teammates (if `--team`)

If `AGENT_TEAM_MODE=false`, skip this step — standalone sub-agents return on their own.

Otherwise, send shutdown requests to all teammates:

```
send follow-up instructions to each teammate: a shutdown request
```

Wait for all teammates to shut down before proceeding.

---

## Phase 4: Consolidate Research

### Step 13: Read Research Reports

Read all research files:

1. `${feature_dir}/research-architecture.md`
2. `${feature_dir}/research-patterns.md`
3. `${feature_dir}/research-integration.md`
4. `${feature_dir}/research-docs.md`

### Step 14: Generate shared.md

Read the shared structure template:

```bash
cat ~/.codex/plugins/ycc/skills/shared-context/templates/shared-structure.md
```

Create `${feature_dir}/shared.md` following the template exactly.

Quality rules:

- Include only verified paths
- Keep descriptions concise and implementation-relevant
- Link patterns to concrete examples
- Mark docs with explicit "must read" contexts

---

## Phase 5: Validation & Summary

### Step 15: Validate shared.md

Run the validation script:

```bash
~/.codex/plugins/ycc/skills/shared-context/scripts/validate-shared.sh "${feature_dir}/shared.md"
```

Fix any issues reported, then re-run until validation passes or only warnings remain.

### Step 16: Clean Up Team (if `--team`)

If `AGENT_TEAM_MODE=false`, skip this step — there is no team to tear down.

Otherwise, delete the team and its resources:

```
close the agent group
```

### Step 17: Display Summary

Provide completion summary. Include dispatch mode (standalone sub-agents or agent team `sc-[feature-name]`):

```markdown
# Shared Context Created

## Location

${feature_dir}/shared.md

## Research Files

- ${feature_dir}/research-architecture.md
- ${feature_dir}/research-patterns.md
- ${feature_dir}/research-integration.md
- ${feature_dir}/research-docs.md

## Dispatch Summary

- Mode: [standalone sub-agents | agent team sc-[feature-name]]
- Researchers: 4
- Inter-agent sharing: [Disabled (Path A) | Enabled (Path B)]

## Summary

- Relevant Files: [count]
- Relevant Tables: [count]
- Relevant Patterns: [count]
- Relevant Docs: [count]

## Next Step (User Triggered)

/parallel-plan [feature-name]
```

**STOP**: Do not execute parallel-plan. Do not write any more files. Do not modify any code. This skill is complete.

---

## Quality Standards

### shared.md Quality Checklist

- [ ] Clear, information-dense overview (3-4 sentences)
- [ ] All file paths verified to exist
- [ ] Brief but useful descriptions for each item
- [ ] Patterns linked to example files where possible
- [ ] Documentation marked with required reading topics

## CRITICAL CONSTRAINTS

- **RESEARCH ONLY** - This skill creates documentation, never plans or implements
- **NO CODE CHANGES** - Do not modify any application source files
- **NO PLANNING** - Do not run parallel-plan or create implementation plans
- **STOP AFTER SUMMARY** - After displaying the completion summary, stop completely
- **DO NOT CHAIN** - Do not automatically proceed to parallel-plan or implement-plan
- **PERSIST ARTIFACTS** - All 4 research files must exist before synthesis
- **CLEAN UP TEAM (Path B only)** - Always `close the agent group` before completing when a team was created

## Output Contract

All files are written to `${feature_dir}/` (resolved via `resolve-plans-dir.sh`).

| File                       | Producer                         | Required Before     |
| -------------------------- | -------------------------------- | ------------------- |
| `research-architecture.md` | architecture-researcher teammate | shared.md synthesis |
| `research-patterns.md`     | patterns-researcher teammate     | shared.md synthesis |
| `research-integration.md`  | integration-researcher teammate  | shared.md synthesis |
| `research-docs.md`         | docs-researcher teammate         | shared.md synthesis |
| `shared.md`                | Team lead (this skill)           | Skill completion    |

**Contract Rules**:

1. Each researcher MUST write its own output file using the Write tool
2. In Path B (`--team`), each teammate MUST share key findings with relevant teammates via send follow-up instructions. In Path A (standalone), inter-agent sharing is unavailable — each sub-agent works independently.
3. The orchestrator MUST run `validate-research-artifacts.sh` before generating shared.md
4. If validation fails, the orchestrator MUST message the failing teammate (Path B) or re-dispatch a sub-agent (Path A) to fix their output
5. No file may be skipped or deferred
6. In Path B, the team MUST be cleaned up (close the agent group) before skill completion

## Monorepo Support

Use `.plans-config` via `resolve-plans-dir.sh`.

Default behavior:

- Plans resolve to repository root `docs/plans/`
- Running from subdirectories still writes to root plans unless local scope is configured

Optional local scope in `.plans-config`:

```yaml
plans_dir: docs/plans
scope: local
```

## Important Notes

- **You are the research orchestrator** - coordinate the 4 researchers and synthesize `shared.md`
- **Choose dispatch mode from `$ARGUMENTS`** - default is standalone sub-agents via `Task`; `--team` switches to teammates under `create an agent group`/`the task tracker`
- **Team setup first (Path B only)** - call `create an agent group` and register all 4 tasks before spawning teammates
- **Spawn in parallel** - a single message with 4 `Task` calls (Path A) or 4 `Agent` calls with `team_name=` + `name=` (Path B)
- **Teammates share findings (Path B only)** - inter-teammate `send follow-up instructions` coordination is unavailable to standalone sub-agents
- **Validate with script** - run `validate-research-artifacts.sh` after researchers complete
- **Message on failure (Path B)** - if validation fails, message the relevant teammate; in Path A, re-dispatch a sub-agent
- **Clean up team (Path B only)** - always `close the agent group` before completing when a team was created
- **Be thorough but concise** - quality over quantity
- **Verify file paths** - all referenced files must exist
- **Foundation for planning** - this document will be used by parallel-plan (run separately by user)
- **Monorepo aware** - automatically resolves correct plans directory
