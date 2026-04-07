---
description: Generate a detailed parallel implementation plan with task dependencies, file ownership, and batch ordering. Step 2 of the planning workflow — requires shared-context output. Produces parallel-plan.md ready for implement-plan.
argument-hint: '[feature-name] [--dry-run]'
---

# Parallel Plan Command

Generate a parallel implementation plan for the specified feature.

**Load and follow the `ycc:parallel-plan` skill**, passing through `$ARGUMENTS`.

The skill analyzes the shared context, designs independent task batches with explicit dependencies, and produces `parallel-plan.md` ready for `implement-plan` to execute.
