# Contributing

## Developer Setup

This repo uses [lefthook](https://github.com/evilmartians/lefthook) for git hooks and
[commitlint](https://commitlint.js.org/) to enforce Conventional Commits at
`commit-msg` time.

```bash
# One-time setup (installs lefthook + commitlint deps, wires .git/hooks/)
./scripts/install-lefthook.sh

# OR: let the npm 'prepare' script run lefthook install for you
npm install
```

What the hooks do:

| Stage        | Command                                                         | Purpose                                     |
| ------------ | --------------------------------------------------------------- | ------------------------------------------- |
| `pre-commit` | `scripts/lint.sh --staged --fix` + `scripts/format.sh --staged` | Lint/format staged Python & shell files     |
| `pre-push`   | `scripts/validate.sh`                                           | Bundle parity + JSON validation (CI parity) |
| `commit-msg` | `commitlint --edit`                                             | Reject non-conventional commit messages     |

Bypass a single operation with `git commit --no-verify` or `git push --no-verify`.
CI is exempt automatically (`CI=true`).

### Migrating from the old `pre-commit` framework

Earlier versions of this repo used the Python `pre-commit` framework via
`.pre-commit-config.yaml`. If your local clone still has it wired, clean up before
running `install-lefthook.sh`:

```bash
pre-commit uninstall
# then:
./scripts/install-lefthook.sh
```

### Claude hooks symlink

`~/.claude/settings.json` is already symlinked to `ycc/settings/settings.json` in this
repo. The `WorktreeCreate` hook registered in that file points to
`~/.claude/hooks/worktree-create.sh`, so you must also expose the hooks directory:

```bash
ln -s "$(pwd)/ycc/settings/hooks" ~/.claude/hooks
```

Run this once from the repo root. After that, Claude Code will invoke
`ycc/settings/hooks/worktree-create.sh` whenever it would otherwise create a worktree
under `<repo>/.claude/worktrees/`, redirecting it to `~/.claude-worktrees/` instead.
Until this symlink is created, `Agent(isolation: "worktree")` falls back to the harness
default and creates worktrees under `<repo>/.claude/worktrees/` (the path the policy in
`ycc/settings/rules/CLAUDE.md:207–224` specifically tries to avoid).

## Repository Model

This repo ships multiple Claude Code plugins from a single marketplace. Currently two:

- **`ycc`** — dev-focused workflows under `ycc/`; cross-generated to Cursor, Codex, opencode.
- **`yci`** — consulting / systems-integration workflows under `yci/`; Claude-native only
  in Phase 0 (cross-target generation deferred to Phase 1a).

New functionality in an existing plugin goes into that plugin's source tree as a new
skill, command, or agent. **New top-level plugins require PRD approval** — see
Scope & Guardrails below for the decision gate.

## Scope & Guardrails

New bundle additions are evaluated against written policy, not memory. These rules come from
`research/plugin-additions/report.md` and apply to every proposal for a new skill, command,
or agent.

- **Do not add another wave of narrow expert skills.** The bundle already ships broad
  coverage; the current bottleneck is maintenance integrity (drift, inventory accuracy,
  generator sync), not missing subjects. Breadth additions without evidence are rejected.
- **Do not create a new top-level plugin without an approved PRD.** The marketplace
  currently ships `ycc` and `yci`. Adding a third plugin requires a PRD at
  `docs/prps/prds/<name>.prd.md` that answers: problem statement, audience and threat
  model, non-goals, phased rollout, success criteria, and the "why this can't live inside
  an existing plugin" argument. The yci PRD (`docs/prps/prds/yci.prd.md`) is the
  reference example. An unjustified new `marketplace.json` entry is rejected by policy.
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
- Does this belong in one of the existing plugins (`ycc` or `yci`)? If yes, add it under
  that plugin's source tree.
- Would this require a NEW top-level plugin and a new `marketplace.json` entry? If yes,
  stop and open a PRD first. Without PRD approval the entry is rejected by policy.
- Has a higher-priority meta-skill or drift fix been scheduled first?
- For hook-related work: does the proposal include a per-target support matrix?

See also: [`ycc/skills/bundle-author/references/when-not-to-scaffold.md`](ycc/skills/bundle-author/references/when-not-to-scaffold.md)
for the skill-author-facing anti-patterns (duplication, one-off tasks, shared-logic
misplacement, agents without consumers, etc.) that complement this policy.

## Structure Requirements

- Claude source plugin manifests: `<plugin>/.claude-plugin/plugin.json` (currently `ycc/` and `yci/`)
- Claude marketplace: `.claude-plugin/marketplace.json` (one entry per plugin)
- Codex generated plugin root: `.codex-plugin/ycc/` (ycc only in Phase 0)
- Codex generated custom agents: `.codex-plugin/agents/` (ycc only in Phase 0)
- Cursor generated bundle: `.cursor-plugin/` (ycc only in Phase 0)
- opencode generated bundle: `.opencode-plugin/` (skills, agents, commands, AGENTS.md, opencode.json — ycc only in Phase 0)
- Skills go in `<plugin>/skills/<skill-name>/SKILL.md`
- Scripts must be executable (`chmod +x`) and use `set -euo pipefail`
- Reference templates go in `<plugin>/skills/<skill-name>/references/`
- yci-specific policy (non-goals, compliance-adapter pattern, customer-data rule) lives in `yci/CONTRIBUTING.md`

## Naming Conventions

- Directories and files: `kebab-case`
- Skills match their slash command name (e.g., skill `git-workflow` -> `/git-workflow`)

## Skills and Commands: When to Pair

Every skill under `ycc/skills/<name>/SKILL.md` ships with a matching
`ycc/commands/<name>.md` **unless** the skill's frontmatter declares
`command: false`. The pairing is enforced by
`scripts/validate-ycc-commands.sh` (wired into `./scripts/validate.sh`).

The two artifacts play **different roles** — they are not duplicates, and
generating one from the other would destroy UX content:

| Artifact    | Description surface                                           | Body content                                                                                                                                          |
| ----------- | ------------------------------------------------------------- | ----------------------------------------------------------------------------------------------------------------------------------------------------- |
| **Skill**   | Auto-trigger matcher (verbose, keyword-dense, scenario-based) | Workflow phases, reference reads, tool invocations.                                                                                                   |
| **Command** | Slash-menu label (concise, flag-aware)                        | Flag documentation tables, usage examples, sibling-command cross-references, agent-type pinning, `$ARGUMENTS` handling, slash-scoped `allowed-tools`. |

**When to opt out with `command: false`**: the skill is passive guidance that
is never directly slash-invoked (`karpathy-guidelines` is the canonical
example — behavioral rules the model reads when relevant code work triggers,
never via `/ycc:karpathy-guidelines`).

**When NOT to opt out**: if a user might ever type `/ycc:<name>` to run the
skill deterministically, keep the command — even a minimal one. Argument
hints, `allowed-tools` tuned for slash-invocation, and the distinct menu
description are all command-only affordances.

The `bundle-author` skill scaffolds both artifacts by default. Pass
`--skill-only` to suppress the command and stamp `command: false` into the
skill frontmatter in one step.

### Cross-target implications

Commands matter for **Claude Code** (native `/ycc:<name>` slash invocation +
argument hints) and **opencode** (first-class slash commands generated from
`ycc/commands/`). Cursor and Codex ignore commands entirely (Cursor folds
guidance into rule files; Codex has no command layer). See
`ycc/skills/_shared/references/target-capability-matrix.md` for the full
matrix.

## Regeneration

After changing `ycc/skills/`, `ycc/agents/`, or `ycc/commands/`, regenerate and validate
compatibility artifacts. After changing `yci/skills/`, `yci/agents/`, or `yci/commands/`,
the unified validator still runs, but no cross-target bundles are emitted in Phase 0.
The recommended path is the unified pair either way:

```bash
./scripts/sync.sh         # iterate PLUGINS; regenerate ycc bundles; breadcrumb for yci
./scripts/validate.sh     # iterate PLUGINS; run every validator (this is what CI runs)
```

Both accept `--only <targets>` with comma-separated values (`inventory, cursor, codex,
opencode, json, yci`). The individual generator/validator scripts are still available if you
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
