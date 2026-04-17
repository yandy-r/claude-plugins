---
description: 'Unified planning workflow — research, analyze, and generate parallel
  implementation plans in one command. Combines shared-context and parallel-plan with
  checkpoint support. Defaults to standalone parallel sub-agents via the opencode
  `task` tool; pass --team (Claude Code only) to orchestrate research, analysis, and
  validation stages as teammates under a shared spawn coordinated subagents/the todo
  tracker with coordinated shutdown. Usage: [--team] [--research-only] [--plan-only]
  [--no-checkpoint] [--optimized] [--dry-run] [feature-name]'
---

# Plan Workflow Command

Run the unified planning pipeline for the specified feature.

**Load and follow the `plan-workflow` skill**, passing through `$ARGUMENTS`.

The skill orchestrates research → shared-context → parallel-plan in a single coordinated flow.

**Flags** (pass before the feature name):

- `--team` — (Claude Code only) Dispatch the research, analysis, and validation stages as teammates under a shared `spawn coordinated subagents`/`the todo tracker` with coordinated shutdown and inter-teammate `send follow-up instructions` coordination. Default is standalone parallel sub-agents via the `Task` tool. Cursor and Codex bundles lack team tools — do not pass `--team` there.
- `--research-only` — Stop after research phase (creates `shared.md` only).
- `--plan-only` — Skip research, use existing `shared.md`.
- `--no-checkpoint` — No pause between research and planning.
- `--optimized` — Use 7-agent optimized deployment (default: 10-agent standard).
- `--dry-run` — Preview the execution plan without deploying agents. With `--team`, also prints the team name and teammate roster.
