---
description: Build shared context documentation for a feature — gathers files, conventions, dependencies, and existing patterns into a single artifact that downstream planning stages can reference. Step 1 of the planning workflow.
argument-hint: '[feature-name] [--dry-run]'
---

# Shared Context Command

Build the shared context document for the specified feature.

**Load and follow the `ycc:shared-context` skill**, passing through `$ARGUMENTS`.

The skill scans the codebase, surfaces relevant files and conventions, and writes a single context artifact that `parallel-plan` and other downstream stages can consume.
