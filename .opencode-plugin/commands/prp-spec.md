---
description: 'Generate a lightweight feature spec for the PRP workflow — single-pass
  with optional codebase/market grounding. Writes to docs/prps/specs/. Sits between
  prp-prd and prp-plan, or works standalone. Usage: [--ground] [feature description
  | path/to/context.md]'
---

# PRP Spec Command

Generate a concise feature specification for the PRP workflow.

**Load and follow the `prp-spec` skill, passing through `$ARGUMENTS`.**

The skill clarifies requirements through light questioning, optionally dispatches `prp-researcher` for codebase and market grounding, and writes a spec to `docs/prps/specs/{kebab-name}.spec.md`.

**Flags**:

- `--ground` — Dispatch `prp-researcher` in dual mode for codebase + market grounding before generating. Default is to generate from provided context only.

```
Usage: /prp-spec [--ground] [feature description | path/to/prd.md]

Examples:
  /prp-spec                                          # Start with questions
  /prp-spec add WebSocket support for live updates   # From description
  /prp-spec docs/prps/prds/notifications.prd.md      # Extract from PRD
  /prp-spec --ground rate limiting for the API       # With researcher grounding

Next step after spec is written:
  /prp-plan docs/prps/specs/{name}.spec.md           # Generate implementation plan
```

For heavyweight multi-agent research (7 parallel agents, writes to `docs/plans/`), use `/feature-research` instead.
