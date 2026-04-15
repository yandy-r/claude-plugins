---
description: Build shared context documentation for a feature — gathers files, conventions, dependencies, and existing patterns into a single artifact that downstream planning stages can reference. Step 1 of the planning workflow. Defaults to standalone parallel sub-agents via the Task tool; pass --team (Claude Code only) to deploy the 4 researchers as teammates under a shared TeamCreate/TaskList with coordinated shutdown.
argument-hint: '[--team] [feature-name] [--dry-run]'
---

# Shared Context Command

Build the shared context document for the specified feature.

**Load and follow the `ycc:shared-context` skill**, passing through `$ARGUMENTS`.

The skill scans the codebase, surfaces relevant files and conventions, and writes a single context artifact that `parallel-plan` and other downstream stages can consume.

**Flags** (pass before the feature name):

- `--team` — (Claude Code only) Dispatch the 4 researchers as teammates under a shared `TeamCreate`/`TaskList` with coordinated shutdown and inter-teammate `SendMessage` coordination. Default is standalone parallel sub-agents via the `Task` tool. Cursor and Codex bundles lack team tools — do not pass `--team` there.
- `--dry-run` — Preview the execution plan without deploying agents. With `--team`, also prints the team name and 4-teammate roster.
