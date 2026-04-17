---
description: 'Research a feature comprehensively before implementation — analyzes
  requirements, gathers external API context, and produces a feature-spec.md ready
  for plan-workflow. Defaults to standalone parallel sub-agents; pass --team (Claude
  Code only) to deploy the 7 researchers as teammates under a shared spawn coordinated
  subagents/the todo tracker with coordinated shutdown. Use when starting a new feature
  and you need structured research before coding. Usage: [--team] [--description "..."]
  [--dry-run] [feature-name]'
---

# Feature Research Command

Research the specified feature and produce a `feature-spec.md`.

**Load and follow the `feature-research` skill**, passing through `$ARGUMENTS`.

The skill deploys 7 parallel researchers (api, business, tech, UX, security, practices, recommendations) to gather requirements, external API context, and prior art, then synthesizes the findings into a structured feature specification under `docs/plans/[feature-name]/`.

**Flags** (pass before the feature name):

- `--team` — (Claude Code only) Dispatch the 7 researchers as teammates under a shared `spawn coordinated subagents`/`the todo tracker` with coordinated shutdown and inter-teammate `send follow-up instructions` coordination. Default is standalone parallel sub-agents via the `Task` tool. Cursor and Codex bundles lack team tools — do not pass `--team` there.
- `--description "..."` — Brief description of the feature; guides the researchers.
- `--dry-run` — Preview the execution plan without deploying agents. With `--team`, also prints the team name and 7-teammate roster.
