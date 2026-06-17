---
description: Whole-project source-of-truth spec generator. Interrogates a raw software idea through a multi-gate process and writes a durable project charter to docs/blueprint.md, then bootstraps the project (init + formatters) from its Bootstrap section. Upstream of prp-prd/prp-spec.
argument-hint: '[project idea] (blank = start with questions) [--update] [--dry-run]'
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
  - TodoWrite
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(test:*)
  - Bash(mkdir:*)
  - Bash(git:*)
---

# Blueprint Command

Run the interactive whole-project blueprint workflow.

**Load and follow the `ycc:blueprint` skill, passing through `$ARGUMENTS`.**

The skill runs a multi-gate interactive flow:
Detect → Initiate → Foundation → Grounding → Scope → Tech Stack → Architecture → Generate → Handoff.
It dispatches the `ycc:prp-researcher` agent during grounding and writes the final charter to
`docs/blueprint.md`. The charter's machine-readable **Bootstrap** section then drives project
setup by orchestrating `/ycc:init` (which chains `/ycc:formatters`).

```
Usage: /ycc:blueprint [project idea] [--update] [--dry-run]

Examples:
  /ycc:blueprint                              # Start from scratch with questions
  /ycc:blueprint a CLI that lints Terraform   # Start from a one-line idea
  /ycc:blueprint --update                     # Refresh an existing docs/blueprint.md (merge)
  /ycc:blueprint --dry-run my idea            # Walk the gates, preview the spec, write nothing

Next steps after the blueprint is written:
  /ycc:init --profile=<p> --templates --git --formatters   # Bootstrap (often run via Handoff)
  /ycc:prp-spec <module>                                    # Per-module feature spec
  /ycc:prp-plan → /ycc:prp-implement                        # Plan and build each module
```

## Where it sits

`blueprint` is the **charter altitude** — run ONCE per project to define the whole software
and stand it up. `prp-prd` / `prp-spec` are **feature altitude** — run repeatedly per module,
seeded by the blueprint's module breakdown. Use `/ycc:plan` for quick conversational planning.
