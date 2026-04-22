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

This repo ships the `ycc` Claude Code plugin — dev-focused workflows under `ycc/`,
cross-generated to Cursor, Codex, and opencode. New functionality goes into `ycc/`
as a new skill, command, or agent. **New top-level plugins in this repo require
PRD approval** — see Scope & Guardrails below for the decision gate.

> **Related**: the consulting / systems-integration toolkit (`yci`) lives in the
> sibling repo [`yandy-r/claude-infra-plugins`](https://github.com/yandy-r/claude-infra-plugins).
> That split (2026-04) is the reference precedent for when scope belongs in a
> separate repo rather than accumulated here.

## Scope & Guardrails

New bundle additions are evaluated against written policy, not memory. These rules come from
`research/plugin-additions/report.md` and apply to every proposal for a new skill, command,
or agent.

- **Do not add another wave of narrow expert skills.** The bundle already ships broad
  coverage; the current bottleneck is maintenance integrity (drift, inventory accuracy,
  generator sync), not missing subjects. Breadth additions without evidence are rejected.
- **Do not create a new top-level plugin without an approved PRD.** The marketplace
  currently ships only `ycc`. Adding a second plugin requires a PRD at
  `docs/prps/prds/<name>.prd.md` that answers: problem statement, audience and threat
  model, non-goals, phased rollout, success criteria, and the "why this can't live inside
  `ycc` or a sibling repo" argument. The `yci` → `claude-infra-plugins` split is the
  reference precedent: when scope cannot coexist with `ycc` without harming it
  (cross-contamination, descriptor pollution, fragility-cliff proximity), prefer a
  sibling repo over a second plugin here. An unjustified new `marketplace.json` entry
  is rejected by policy.
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
- Does this belong in `ycc`? If yes, add it under `ycc/skills/`, `ycc/commands/`, or `ycc/agents/`.
- Does this belong in a sibling repo (e.g., consulting/SI scope → `claude-infra-plugins`)?
  If yes, PR it there.
- Would this require a NEW top-level plugin and a new `marketplace.json` entry in this
  repo? If yes, stop and open a PRD first. Without PRD approval the entry is rejected
  by policy.
- Has a higher-priority meta-skill or drift fix been scheduled first?
- For hook-related work: does the proposal include a per-target support matrix?

See also: [`ycc/skills/bundle-author/references/when-not-to-scaffold.md`](ycc/skills/bundle-author/references/when-not-to-scaffold.md)
for the skill-author-facing anti-patterns (duplication, one-off tasks, shared-logic
misplacement, agents without consumers, etc.) that complement this policy.

## Structure Requirements

- Claude source plugin manifest: `ycc/.claude-plugin/plugin.json`
- Claude marketplace: `.claude-plugin/marketplace.json` (single entry)
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
the compatibility bundles:

```bash
./scripts/sync.sh         # regenerate every Cursor / Codex / opencode bundle
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
