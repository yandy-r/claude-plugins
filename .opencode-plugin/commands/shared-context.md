---
description: 'Build shared context documentation for a feature — gathers files, conventions,
  dependencies, and existing patterns into a single artifact that downstream planning
  stages can reference. Step 1 of the planning workflow. Defaults to standalone parallel
  sub-agents via the native `subagent` tool. Usage: [feature-name] [--dry-run]'
---

# Shared Context Command

> **OpenCode V2 compatibility:** `--team` is unsupported. If it is supplied, abort before setup or dispatch and ask the caller to rerun without it. This target uses native standalone `subagent` calls only.

Thin alias for `plan-workflow --research-only` (research stage with `--no-checkpoint`).

Build the shared context document for the specified feature.

**Load and follow the `shared-context` skill**, passing through `$ARGUMENTS`.

The skill scans the codebase, surfaces relevant files and conventions, and writes a single context artifact that `parallel-plan` and other downstream stages can consume.

**Flags** (pass before the feature name):
