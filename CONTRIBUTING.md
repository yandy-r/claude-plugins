# Contributing

## Repository Model

This repo no longer accepts new top-level Claude plugins. All new functionality goes into the
existing `ycc` source plugin under `ycc/`, then flows through the generated Cursor, Codex, and
opencode compatibility bundles.

## Scope & Guardrails

New bundle additions are evaluated against written policy, not memory. These rules come from
`research/plugin-additions/report.md` and apply to every proposal for a new skill, command,
or agent.

- **Do not add another wave of narrow expert skills.** The bundle already ships broad
  coverage; the current bottleneck is maintenance integrity (drift, inventory accuracy,
  generator sync), not missing subjects. Breadth additions without evidence are rejected.
- **Do not create a new top-level plugin.** The repo contract is one plugin (`ycc`). All
  new functionality goes under `ycc/` and is reached via the `ycc:` namespace. Adding
  entries to `.claude-plugin/marketplace.json` breaks the 2.0 consolidation contract.
- **Do not market hooks as uniform across targets.** Claude, Cursor, Codex, and opencode each
  have different hook support and maturity. Any hook-related addition must ship with a
  per-target support matrix.
- **Meta-skills and internal optimizations precede new domain coverage.** Authoring
  workflows, release workflows, compatibility audits, validator CI, and source-driven
  inventory come before any new subject-matter skill.

### Proposing New Capabilities

Before opening a PR for a new skill, command, or agent, answer each question below. If any
answer points elsewhere, revise the proposal before writing code.

- Could this extend an existing skill (a new phase, flag, or reference file) instead of
  becoming a new one?
- Would this require a new top-level plugin or a `marketplace.json` entry? If yes, stop —
  this is rejected by policy.
- Has a higher-priority meta-skill or drift fix been scheduled first?
- For hook-related work: does the proposal include a per-target support matrix?

See also: [`ycc/skills/bundle-author/references/when-not-to-scaffold.md`](ycc/skills/bundle-author/references/when-not-to-scaffold.md)
for the skill-author-facing anti-patterns (duplication, one-off tasks, shared-logic
misplacement, agents without consumers, etc.) that complement this policy.

## Structure Requirements

- Claude source plugin manifest: `ycc/.claude-plugin/plugin.json`
- Claude marketplace: `.claude-plugin/marketplace.json`
- Codex generated plugin root: `.codex-plugin/ycc/`
- Codex generated custom agents: `.codex-plugin/agents/`
- Cursor generated bundle: `.cursor-plugin/`
- opencode generated bundle: `.opencode-plugin/` (skills, agents, commands, AGENTS.md, opencode.json)
- Skills go in `ycc/skills/<skill-name>/SKILL.md`
- Scripts must be executable (`chmod +x`) and use `set -euo pipefail`
- Reference templates go in `ycc/skills/<skill-name>/references/`

## Naming Conventions

- Directories and files: `kebab-case`
- Skills match their slash command name (e.g., skill `git-workflow` -> `/git-workflow`)

## Regeneration

After changing `ycc/skills/`, `ycc/agents/`, or `ycc/commands/`, regenerate and validate
compatibility artifacts. The recommended path is the unified pair:

```bash
./scripts/sync.sh         # regenerate inventory + cursor + codex + opencode bundles
./scripts/validate.sh     # run every validator (this is what CI runs)
```

Both accept `--only <targets>` with comma-separated values (`inventory, cursor, codex,
opencode, json`). The individual generator/validator scripts are still available if you
need to target a single surface:

```bash
# Codex
./scripts/generate-codex-skills.sh && ./scripts/validate-codex-skills.sh
./scripts/generate-codex-agents.sh && ./scripts/validate-codex-agents.sh
./scripts/generate-codex-plugin.sh && ./scripts/validate-codex-plugin.sh

# Cursor
./scripts/generate-cursor-skills.sh && ./scripts/validate-cursor-skills.sh
./scripts/generate-cursor-agents.sh && ./scripts/validate-cursor-agents.sh
./scripts/generate-cursor-rules.sh  && ./scripts/validate-cursor-rules.sh

# opencode
./scripts/generate-opencode-skills.sh   && ./scripts/validate-opencode-skills.sh
./scripts/generate-opencode-agents.sh   && ./scripts/validate-opencode-agents.sh
./scripts/generate-opencode-commands.sh && ./scripts/validate-opencode-commands.sh
./scripts/generate-opencode-plugin.sh   && ./scripts/validate-opencode-plugin.sh
```

## Pull Requests

- Include a description of the source change and any regenerated compatibility artifacts
- Ensure relevant marketplace/manifests are updated when generators change them
