---
description: >
  Generate a lightweight feature spec for the PRP workflow — single-pass with optional
  codebase/market grounding. Writes to docs/prps/specs/. Sits between prp-prd and prp-plan,
  or works standalone.
argument-hint: '[--ground] [feature description | path/to/context.md]'
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - Agent
  - WebSearch
  - WebFetch
  - AskUserQuestion
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - Bash(git:*)
---

# PRP Spec Command

Generate a concise feature specification for the PRP workflow.

**Load and follow the `ycc:prp-spec` skill, passing through `$ARGUMENTS`.**

The skill clarifies requirements through light questioning, optionally dispatches `ycc:prp-researcher` for codebase and market grounding, and writes a spec to `docs/prps/specs/{kebab-name}.spec.md`.

**Flags**:

- `--ground` — Dispatch `ycc:prp-researcher` in dual mode for codebase + market grounding before generating. Default is to generate from provided context only.

```
Usage: /ycc:prp-spec [--ground] [feature description | path/to/prd.md]

Examples:
  /ycc:prp-spec                                          # Start with questions
  /ycc:prp-spec add WebSocket support for live updates   # From description
  /ycc:prp-spec docs/prps/prds/notifications.prd.md      # Extract from PRD
  /ycc:prp-spec --ground rate limiting for the API       # With researcher grounding

Next step after spec is written:
  /ycc:prp-plan docs/prps/specs/{name}.spec.md           # Generate implementation plan
```

For heavyweight multi-agent research (7 parallel agents, writes to `docs/plans/`), use `/ycc:feature-research` instead.
