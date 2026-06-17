---
description: 'Whole-project source-of-truth spec generator. Interrogates a raw software
  idea through a multi-gate process and writes a durable project charter to docs/blueprint.md,
  then bootstraps the project (init + formatters) from its Bootstrap section. Upstream
  of prp-prd/prp-spec. Usage: [project idea] (blank = start with questions) [--update]
  [--dry-run]'
---

# Blueprint Command

Run the interactive whole-project blueprint workflow.

**Load and follow the `blueprint` skill, passing through `$ARGUMENTS`.**

The skill runs a multi-gate interactive flow:
Detect → Initiate → Foundation → Grounding → Scope → Tech Stack → Architecture → Generate → Handoff.
It dispatches the `prp-researcher` agent during grounding and writes the final charter to
`docs/blueprint.md`. The charter's machine-readable **Bootstrap** section then drives project
setup by orchestrating `/init` (which chains `/formatters`).

```
Usage: /blueprint [project idea] [--update] [--dry-run]

Examples:
  /blueprint                              # Start from scratch with questions
  /blueprint a CLI that lints Terraform   # Start from a one-line idea
  /blueprint --update                     # Refresh an existing docs/blueprint.md (merge)
  /blueprint --dry-run my idea            # Walk the gates, preview the spec, write nothing

Next steps after the blueprint is written:
  /init --profile=<p> --templates --git --formatters   # Bootstrap (often run via Handoff)
  /prp-spec <module>                                    # Per-module feature spec
  /prp-plan → /prp-implement                        # Plan and build each module
```

## Where it sits

`blueprint` is the **charter altitude** — run ONCE per project to define the whole software
and stand it up. `prp-prd` / `prp-spec` are **feature altitude** — run repeatedly per module,
seeded by the blueprint's module breakdown. Use `/plan` for quick conversational planning.
