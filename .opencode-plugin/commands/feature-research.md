---
description: 'Research a feature comprehensively before implementation — analyzes
  requirements, gathers external API context, and produces a feature-spec.md ready
  for plan-workflow. Defaults to standalone parallel sub-agents. Use when starting
  a new feature and you need structured research before coding. Usage: [--description
  "..."] [--dry-run] [feature-name]'
---

# Feature Research Command

> **OpenCode V2 compatibility:** `--team` is unsupported. If it is supplied, abort before setup or dispatch and ask the caller to rerun without it. This target uses native standalone `subagent` calls only.

Research the specified feature and produce a `feature-spec.md`.

**Load and follow the `feature-research` skill**, passing through `$ARGUMENTS`.

The skill deploys 7 parallel researchers (api, business, tech, UX, security, practices, recommendations) to gather requirements, external API context, and prior art, then synthesizes the findings into a structured feature specification under `docs/plans/[feature-name]/`.

**Flags** (pass before the feature name):

- `--description "..."` — Brief description of the feature; guides the researchers.
