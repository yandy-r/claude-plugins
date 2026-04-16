# Pattern Recognition: plugin-additions

## Executive Summary

Four patterns repeat across the repo audit and the external ecosystem: convergence on a shared primitive set, growth pressure causing drift, hooks turning instructions into enforcement, and async agents increasing the value of release/compatibility automation.

## Recurring Patterns

### Pattern 1: Platform convergence

- Claude, Codex, Cursor, and GitHub Copilot are all clustering around repo instructions, reusable skills/rules, hooks, MCP, and specialized agents.
- **Implication**: `ycc` should invest in workflows that sit on top of those common primitives.

### Pattern 2: Catalog growth outpaces hygiene

- The repo already has more skills than README claims and more commands than documented.
- **Implication**: Inventory generation and sync checks are overdue.

### Pattern 3: Hooks are the bridge from advice to enforcement

- The repo documents hooks but does not operationalize them.
- **Implication**: Hook workflows are now a high-leverage addition.

### Pattern 4: Generated artifacts need a product workflow

- The repo has generators and validators, but no user-facing ycc workflow to run them as one release-quality path.
- **Implication**: A release/sync/compatibility layer is the natural next step.

## Unexpected Historical Echo

This looks like earlier codegen-heavy toolchains: once derived artifacts multiply, the winning move is always to centralize authoring and automate verification.

## Key Insight

The repo's next phase is operational maturity, not catalog explosion.
