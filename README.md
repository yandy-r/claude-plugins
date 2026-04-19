# claude-plugins

A single Claude Code plugin (`ycc`) bundling workflow orchestration, parallel planning, documentation, research, and project management. The repository also generates native compatibility bundles for Cursor, Codex, and opencode.

> **2.0.0 breaking change.** Versions ≤ 1.x shipped 9 separate plugins (`ask`, `plan-workflow`, `git-workflow`, `implement-plan`, `code-report`, `deep-research`, `orchestrate`, `write-docs`, `project`). 2.0.0 collapses all of them into a single `ycc` plugin so every skill is accessible via `ycc:{skill}`. Re-install after upgrading.

## What's inside

<!-- BEGIN:GENERATED-COUNTS -->

The source plugin ships **44 skills**, **43 slash commands** (most skills have a matching command), and **52 agents**.

<!-- END:GENERATED-COUNTS -->

<!-- BEGIN:GENERATED-COMMANDS -->

| Command / Skill            | Purpose                                                                                                                                                                                 |
| -------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `/ycc:ask`                 | Ask questions about the codebase without making changes - get guidance, impact analysis, or comparisons                                                                                 |
| `/ycc:bundle-author`       | Scaffold new source-of-truth content in the ycc bundle (skill, optional matching command and agent)                                                                                     |
| `/ycc:bundle-release`      | Prepare a ycc bundle release — preflight, bump, regenerate, validate, draft notes (no auto-commit)                                                                                      |
| `/ycc:clean`               | Orchestrate parallel cleanup agents to find and remove unnecessary project files                                                                                                        |
| `/ycc:code-report`         | Generate structured implementation reports documenting changes made during plan execution.                                                                                              |
| `/ycc:code-review`         | Code review — local uncommitted changes or a GitHub PR (pass PR number/URL for PR mode).                                                                                                |
| `/ycc:compatibility-audit` | Audit cross-target compatibility of the ycc bundle across Claude, Cursor, Codex, and opencode targets                                                                                   |
| `/ycc:deep-research`       | Conduct strategic multi-perspective research using the Asymmetric Research Squad methodology with 8 specialized personas.                                                               |
| `/ycc:feature-research`    | Research a feature comprehensively before implementation — analyzes requirements, gathers external API context, and produces a feature-spec.md ready for plan-workflow.                 |
| `/ycc:formatters`          | Bootstrap a best-practices lint/format environment — installs a self-contained scripts/style.sh bundle, per-language tool configs, runnable aliases (package.json/Makefile/justfile)... |
| `/ycc:frontend-design`     | Create distinctive, production-grade frontend interfaces with intentional visual direction — typography, color, spacing rhythm, layout composition, motion, and atmosphere.             |
| `/ycc:frontend-patterns`   | Frontend patterns for React and Next.js — composition, compound components, render props, custom hooks, state management with Context+useReducer, data fetching, performance optimiz... |
| `/ycc:frontend-slides`     | Create stunning, animation-rich, zero-dependency HTML presentations from scratch or by converting PowerPoint files.                                                                     |
| `/ycc:git-cleanup`         | Audit and clean up stale git resources (branches, worktrees, remote-tracking refs, stashes, tags, PRs, issues) on GitHub/GitLab.                                                        |
| `/ycc:git-workflow`        | Git commit and documentation workflow manager.                                                                                                                                          |
| `/ycc:go-patterns`         | Idiomatic Go patterns, best practices, and conventions for building robust, efficient, and maintainable Go applications.                                                                |
| `/ycc:go-testing`          | Go testing patterns including table-driven tests, subtests, benchmarks, fuzzing, and test coverage.                                                                                     |
| `/ycc:hooks-workflow`      | Generate target-aware hook configuration from ycc rule guidance with graceful fallbacks.                                                                                                |
| `/ycc:implement-plan`      | Execute a parallel implementation plan by deploying implementor agents in dependency-resolved batches.                                                                                  |
| `/ycc:init`                | Initialize workspace — profile project, emit CLAUDE.md/AGENTS.md/.cursor/rules, optional GitHub templates, git conventions, and Claude CLI config.                                      |
| `/ycc:orchestrate`         | Orchestrate multiple specialized agents to accomplish a complex task through intelligent decomposition and parallel execution.                                                          |
| `/ycc:parallel-plan`       | Generate a detailed parallel implementation plan with task dependencies, file ownership, and batch ordering.                                                                            |
| `/ycc:plan`                | Lightweight conversational planner.                                                                                                                                                     |
| `/ycc:plan-workflow`       | Unified planning workflow — research, analyze, and generate parallel implementation plans in one command.                                                                               |
| `/ycc:prp-commit`          | Quick natural-language git commit helper — describe what to commit in plain English (blob glob, filter phrase, or topic).                                                               |
| `/ycc:prp-implement`       | Execute a PRP plan file with per-task validation loops.                                                                                                                                 |
| `/ycc:prp-plan`            | Create a single-pass implementation plan from a feature description or PRD.                                                                                                             |
| `/ycc:prp-pr`              | Create a GitHub PR from the current branch — discovers templates, analyzes commits, references PRP artifacts, pushes, and opens the PR via gh.                                          |
| `/ycc:prp-prd`             | Interactive PRD generator — problem-first, hypothesis-driven product spec built through iterative questioning and dual-mode grounding research.                                         |
| `/ycc:prp-spec`            | Generate a lightweight feature spec for the PRP workflow — single-pass with optional codebase/market grounding.                                                                         |
| `/ycc:python-patterns`     | Idiomatic Python patterns, PEP 8 conventions, type hints, dataclasses, context managers, decorators, and best practices for building robust, maintainable Python applications.          |
| `/ycc:python-testing`      | Python testing patterns using pytest — TDD methodology, fixtures (function/module/session scopes), parametrization, markers, mocking with unittest.mock, async tests with pytest-asy... |
| `/ycc:releaser`            | Prepare and cut a GitHub release for any project — detects toolchain, drafts changelog, plans platform/arch artifacts, optionally generates or audits release CI.                       |
| `/ycc:research-to-issues`  | Convert research, feature specs, and implementation plans into structured GitHub issues with tracking hierarchy, labels, and priority.                                                  |
| `/ycc:resume-session`      | Load the most recent session file from ~/.claude/session-data/ and resume work with full context.                                                                                       |
| `/ycc:review-fix`          | Plan and apply fixes for findings from a code-review artifact.                                                                                                                          |
| `/ycc:rust-patterns`       | Idiomatic Rust patterns, ownership, error handling, traits, concurrency, and best practices for building safe, performant applications.                                                 |
| `/ycc:rust-testing`        | Rust testing patterns including unit tests, integration tests, async testing, property-based testing, mocking, and coverage.                                                            |
| `/ycc:save-session`        | Save current session state to a dated file in ~/.claude/session-data/ so work can be resumed in a future session with full context.                                                     |
| `/ycc:shared-context`      | Build shared context documentation for a feature — gathers files, conventions, dependencies, and existing patterns into a single artifact that downstream planning stages can refere... |
| `/ycc:ts-patterns`         | Idiomatic TypeScript patterns — strict type system, discriminated unions, generic inference, `satisfies`, branded types, errors as values, ESM/CJS modules with `exports` maps, Prom... |
| `/ycc:ts-testing`          | TypeScript testing patterns using Vitest as the primary runner — TDD workflow, unit tests, integration tests, async tests with fake timers, parameterized tests via `test.each`, pro... |
| `/ycc:write-docs`          | Orchestrate 5 specialized documentation agents in parallel to analyze codebase and create comprehensive documentation.                                                                  |

<!-- END:GENERATED-COMMANDS -->

### Agents

<!-- BEGIN:GENERATED-AGENTS -->

The plugin bundles **52** specialized agents covering codebase analysis, language experts (Go, Rust, Python, TypeScript), reviewers, planners, documenters, and infrastructure architects.

<details>
<summary>Full agent list (52 agents, grouped by role)</summary>

- **Language experts & implementors** (12): `frontend-ui-developer`, `go-api-architect`, `go-expert-architect`, `nextjs-ux-ui-expert`, `nodejs-backend-architect`, `nodejs-backend-developer`, `python-developer`, `python-expert-architect`, `rust-build-resolver`, `rust-expert-architect`, `typescript-developer`, `typescript-expert-architect`
- **Code review & quality** (4): `code-reviewer`, `code-simplifier`, `review-fixer`, `rust-reviewer`
- **Research & discovery** (10): `code-explorer`, `code-finder`, `code-researcher`, `codebase-advisor`, `feature-researcher`, `library-docs-writer`, `practices-researcher`, `prp-researcher`, `research-specialist`, `root-cause-analyzer`
- **Architecture & planning** (5): `architect`, `architecture-analyst`, `code-architect`, `planner`, `test-strategy-planner`
- **Documentation** (7): `api-docs-expert`, `api-documenter`, `code-documenter`, `docs-git-committer`, `documentation-writer`, `feature-writer`, `readme-generator`
- **Infrastructure & DevOps** (7): `ansible-automation-expert`, `cloudflare-architect`, `cloudflare-developer`, `reverse-proxy-architect`, `systems-engineering-expert`, `terraform-architect`, `terraform-developer`
- **Databases** (3): `db-modifier`, `sql-database-developer`, `turso-database-architect`
- **Workflow utilities** (4): `git-cleanup`, `implementor`, `project-file-cleaner`, `releaser`

</details>

<!-- END:GENERATED-AGENTS -->

- **Claude Code:** reference any of them via `subagent_type: "ycc:{agent-name}"`. Canonical source lives in [`ycc/agents/`](ycc/agents/).
- **Cursor:** generated, Cursor-native copies live in [`.cursor-plugin/agents/`](.cursor-plugin/agents/) (produced from `ycc/agents/` — see [Cursor IDE sync](#cursor-ide-sync)).
- **Codex:** generated, Codex-native custom-agent TOMLs live in [`.codex-plugin/agents/`](.codex-plugin/agents/) (produced from `ycc/agents/` and synced to `~/.codex/agents/` by `install.sh --target codex`).
- **opencode:** generated, opencode-native agent markdown files live in [`.opencode-plugin/agents/`](.opencode-plugin/agents/) (produced from `ycc/agents/` and synced to `~/.config/opencode/agents/` by `install.sh --target opencode`). Invoke via `@agent-name` mention or the built-in `task` tool.

**Contributing:** before proposing a new skill, command, or agent, read the Scope & Guardrails policy in [`CONTRIBUTING.md`](CONTRIBUTING.md#scope--guardrails).

## Installation

```bash
# Add the marketplace
/plugin marketplace add yandy-r/claude-plugins

# Install the bundle
/plugin install ycc@ycc
```

Or enable in `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "ycc@ycc": true
  }
}
```

## Workflow composition

The planning skills compose into a pipeline:

```
ycc:feature-research → ycc:shared-context → ycc:parallel-plan → ycc:implement-plan → ycc:code-report → ycc:git-workflow
   (research)            (gather files)       (design tasks)      (deploy agents)      (document)         (commit/PR)
```

Use `ycc:plan-workflow` to run the full pipeline, or invoke individual stages.

## Local Sync Targets

- Cursor loads **skills**, **agents**, and **rules** from `~/.cursor/{skills,agents,rules}/`.
- Codex uses a **plugin** for skills/MCP plus **custom agents** in `~/.codex/agents/`.
- opencode loads **skills**, **agents**, and **commands** from `~/.config/opencode/{skills,agents,commands}/` and reads MCP + default-model config from `~/.config/opencode/opencode.json`.

This repository maintains generated compatibility trees under **`.cursor-plugin/`**, **`.codex-plugin/`**, and **`.opencode-plugin/`**.

Shared MCP server definitions live in [`mcp-configs/mcp.json`](mcp-configs/mcp.json). The installer is organized around **targets** and **steps** — each target exposes a set of steps that can be run by default, added with an additive flag, or isolated with `--only`.

| Target     | Steps                      | Notes                                                                                                                                                                                                                                          |
| ---------- | -------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `claude`   | `settings`, `mcp`, `hooks` | No default step — pass `--settings`, `--mcp`, `--hooks`, or `--only <steps>`. `settings` also links user-global `CLAUDE.md` + `AGENTS.md`. `hooks` symlinks `ycc/settings/hooks/` into `~/.claude/hooks/` (enables the `WorktreeCreate` hook). |
| `cursor`   | `base`, `mcp`, `settings`  | `base` = generate + validate + format + rsync `skills/`, `agents/`, `rules/` into `~/.cursor/`. `settings` links user-global rules.                                                                                                            |
| `codex`    | `base`, `settings`         | `base` = generate + validate + format + sync plugin & agents + merge `~/.agents/.../marketplace.json`. `settings` also links user-global rules.                                                                                                |
| `opencode` | `base`, `settings`         | `base` = generate + validate + format + rsync `skills/agents/commands` into `~/.config/opencode/`. `settings` symlinks config + AGENTS.md.                                                                                                     |
| `all`      | —                          | Runs `claude`, `cursor`, `codex`, then `opencode`; step flags propagate.                                                                                                                                                                       |

Step reference:

- `base` — full generator/validator/sync pipeline for the target (cursor/codex/opencode).
- `settings` — symlinks per-target config files into the IDE's config dir. Every target also links the generic user-global rules from [`ycc/settings/rules/`](ycc/settings/rules/) (see that dir's README for the scope rationale):
  - claude: `ycc/settings/{settings.json,statusline-command.sh}` + `ycc/settings/rules/{CLAUDE.md,AGENTS.md}` → `~/.claude/`
  - cursor: `ycc/settings/rules/{CLAUDE.md,AGENTS.md}` → `~/.cursor/` (top level — NOT inside `~/.cursor/rules/`, which gets `rsync --delete`d during `base`)
  - codex: `.codex-plugin/config/{config.toml,default.rules}` + `ycc/settings/rules/{CLAUDE.md,AGENTS.md}` → `~/.codex/`
  - opencode: `.opencode-plugin/{opencode.json,AGENTS.md}` → `~/.config/opencode/` (opencode's `AGENTS.md` is generator-produced from the repo `CLAUDE.md`, not the generic rules tree)
- `mcp` — shared `mcp-configs/mcp.json` integration:
  - claude: merges `mcpServers` into `~/.claude.json` (preserves other keys such as `projects`)
  - cursor: symlinks `mcp-configs/mcp.json` → `~/.cursor/mcp.json` (kept in sync across systems)
  - opencode: there is no separate `mcp` step — the generated `opencode.json` already embeds the translated MCP block, and enabling it is part of the `settings` step.
- `hooks` — claude-only. Symlinks `ycc/settings/hooks/` → `~/.claude/hooks/`, which wires the `WorktreeCreate` hook that redirects harness-managed worktrees from `<repo>/.claude/worktrees/` to `~/.claude-worktrees/`. Silently ignored by targets without hook support.

The rules linker refuses to overwrite a real (non-symlink) `CLAUDE.md` / `AGENTS.md` at a destination. Pass `--force` to replace a user-authored file.

### Install targets

```bash
# Default (no --only): run base step if the target has one, then any additive flags.
./install.sh --target cursor                        # base only
./install.sh --target cursor --mcp                  # base + symlink MCP
./install.sh --target cursor --settings             # base + link user-global rules
./install.sh --target codex --settings              # base + codex config + rules
./install.sh --target opencode                      # base only (skills + agents + commands)
./install.sh --target opencode --settings           # base + link opencode.json + AGENTS.md
./install.sh --target claude --settings --mcp       # symlink settings + rules + merge MCP
./install.sh --target claude --settings --mcp --hooks  # +worktree-redirect hook
./install.sh --target all --settings --mcp          # everything across all targets
./install.sh --target all --settings --force        # same, overwriting user-authored rules

# Exclusive (--only): run exactly the listed steps, nothing else.
./install.sh --target claude   --only mcp           # merge MCP, skip settings link
./install.sh --target cursor   --only mcp           # just the MCP symlink
./install.sh --target cursor   --only settings      # just the cursor rules symlinks
./install.sh --target codex    --only settings      # just the codex config + rules symlinks
./install.sh --target codex    --only base,settings # equivalent to default + --settings
./install.sh --target opencode --only settings      # just the opencode config + rules symlinks
```

`--settings` and `--mcp` are **additive** on top of the default (`base`) step. `--only <steps>` is **exclusive** and overrides both defaults and additive flags. Invalid steps for a target (e.g. `--only settings` on `cursor`) fail fast with a clear error.

The `codex` target syncs:

- plugin source: [`.codex-plugin/ycc/`](.codex-plugin/ycc/) → `~/.codex/plugins/ycc/`
- native custom agents: [`.codex-plugin/agents/`](.codex-plugin/agents/) → `~/.codex/agents/`
- user marketplace entry: `~/.agents/plugins/marketplace.json`

After running the Codex target, restart Codex, open `/plugins`, and install `ycc` from your local marketplace if it is not already installed.

### Codex notes

- Codex support is **native**, not a Cursor-style copy. Skills are packaged as a Codex plugin and agents are emitted as Codex custom-agent TOMLs.
- Codex does **not** support this repo's custom slash-command layer as installable artifacts. Use the bundled skills directly with `$skill-name` or by invoking the installed `ycc` plugin, and use Codex built-ins such as `/plan` and `/review` where applicable.
- Generated Codex skill references assume the managed install location `~/.codex/plugins/ycc/` for bundled helper scripts and references.

### opencode notes

- opencode support is **native**. Skills install at `~/.config/opencode/skills/`, agents at `~/.config/opencode/agents/`, and commands at `~/.config/opencode/commands/`. opencode loads `SKILL.md` on demand via the built-in `skill` tool; agents respond to `@mention` or the built-in `task` tool; commands run as `/<name>` in the TUI.
- opencode has no `${PLUGIN_ROOT}` variable, so generated skill bodies reference absolute paths (e.g. `~/.config/opencode/skills/foo/...`) rather than a runtime-injected root.
- **Default model**: the generated `opencode.json` sets `model: "openai/gpt-5.4"` with `reasoningEffort: "high"` and `textVerbosity: "low"`. Users need `OPENAI_API_KEY` in their environment, or can run `opencode auth login openai` once. Anthropic/Claude is not first-class in opencode (Anthropic blocked opencode client spoofing in January 2026; opencode 1.3.0 removed the built-in Anthropic OAuth plugin) — users who want different models can override via `scripts/opencode_model_aliases.local.json` (gitignored, merged on top of `scripts/opencode_model_aliases.json`).
- **Hooks** are marked `partial` in the capability matrix: opencode's lifecycle hooks require a TypeScript plugin module, which the `ycc` bundle does not ship in v1. Hook guidance is emitted as rule-embedded notes only.

### Unified sync and validate

The recommended workflow is a single entry point that regenerates (or validates) every derived artifact in one call:

```bash
./scripts/sync.sh        # regenerate everything: inventory, Cursor, Codex
./scripts/validate.sh    # run every validator; CI runs this on push and PR
```

Both accept `--only <targets>` with comma-separated values. Valid targets:

- `inventory` — `docs/inventory.json` and the `GENERATED-*` regions of `README.md`
- `cursor` — `.cursor-plugin/` agents, skills, and rules
- `codex` — `.codex-plugin/` skills, agents, and plugin metadata
- `opencode` — `.opencode-plugin/` skills, agents, commands, and plugin metadata (opencode.json + AGENTS.md)
- `json` — JSON-lint `.claude-plugin/marketplace.json` and `ycc/.claude-plugin/plugin.json` (validate only)

Examples:

```bash
./scripts/sync.sh --only inventory
./scripts/validate.sh --only cursor,codex,opencode
./scripts/sync.sh --only opencode
```

CI runs `./scripts/validate.sh` via [`.github/workflows/validate.yml`](.github/workflows/validate.yml) and fails the job on any generated drift, so local and CI paths are identical.

### Regenerate inventory

`docs/inventory.json` is the canonical manifest of skills, commands, and agents. The inventory generator also rewrites three marker-bounded regions of `README.md`:

- **GENERATED-COUNTS** — the skills/commands/agents counts sentence
- **GENERATED-COMMANDS** — the capability table
- **GENERATED-AGENTS** — the agent-count sentence

Each region is bounded by HTML-comment markers (`BEGIN:` / `END:`) that must live on their own line. Content inside the markers is overwritten by the generator — edits there will be clobbered. Everything else in `README.md` is hand-authored.

```bash
./scripts/generate-inventory.sh
./scripts/validate-inventory.sh
```

Skills that legitimately lack a matching slash command (for example, passive trigger-only skills) appear in the generator's `skills without commands` summary — this is informational, not an error.

### Regenerate Cursor agents

`ycc/agents/*.md` is the **source of truth**. After editing an agent there, regenerate the Cursor copies and validate:

```bash
./scripts/generate-cursor-agents.sh
./scripts/validate-cursor-agents.sh
```

The generator **overwrites** each matching `*.md` and **deletes** any `*.md` under `.cursor-plugin/agents/` that no longer exists in `ycc/agents/`, so the two trees stay in lockstep.

Cursor model normalization is applied during generation:

- Generated Cursor agents always emit `model: inherit` or `model: fast`.
- `fast` assignments are controlled by [`scripts/cursor_fast_agents.json`](scripts/cursor_fast_agents.json).
- Any non-allowlisted agent is normalized to `inherit`.
- [`scripts/validate-cursor-agents.sh`](scripts/validate-cursor-agents.sh) fails on legacy shorthand model tokens (for example `opus`, `sonnet`, `haiku`) in generated Cursor output.

Commit changes to both `ycc/agents/` and `.cursor-plugin/agents/` together.

### Regenerate Cursor skills

`ycc/skills/` is the **source of truth**. After editing skills (including scripts and templates), regenerate the Cursor tree and validate:

```bash
./scripts/generate-cursor-skills.sh
./scripts/validate-cursor-skills.sh
```

The generator **mirrors** the full directory (new/updated files and **deletions**), preserves Unix file modes (e.g. executable `*.sh`), and applies Cursor-native rewrites (for example `CLAUDE_PLUGIN_ROOT` → `CURSOR_PLUGIN_ROOT`, `/ycc:foo` → `/foo`, `~/.claude/` → `~/.cursor/` where applicable).

**`CURSOR_PLUGIN_ROOT`:** Generated skills reference bundled files as `${CURSOR_PLUGIN_ROOT}/skills/...`. Set this to the absolute path of your **plugin root** (the directory that contains a `skills/` folder — e.g. this repo’s [`.cursor-plugin`](.cursor-plugin) when developing, or your installed plugin directory under `~/.cursor/plugins/` after installation).

Commit changes to both `ycc/skills/` and `.cursor-plugin/skills/` together.

### Regenerate Cursor rules

`ycc/rules/` is the **source of truth** (nested `common/`, language folders, `web/`, etc.). After editing `.md` sources, regenerate Cursor `.mdc` rules and validate:

```bash
./scripts/generate-cursor-rules.sh
./scripts/validate-cursor-rules.sh
```

The generator writes **nested** `.mdc` files (same folder layout as `ycc/rules/`), converts Claude-style `paths:` frontmatter to `globs:`, mirrors the tree exactly (including deletions), and applies the same Cursor-native text rewrites as skills.

### Regenerate Codex skills, plugin metadata, and agents

`ycc/skills/` and `ycc/agents/` remain the **source of truth**. After editing either tree, regenerate the Codex artifacts and validate:

```bash
./scripts/generate-codex-skills.sh
./scripts/generate-codex-agents.sh
./scripts/generate-codex-plugin.sh
./scripts/validate-codex-skills.sh
./scripts/validate-codex-agents.sh
./scripts/validate-codex-plugin.sh
```

Codex output layout:

- [`.codex-plugin/ycc/`](.codex-plugin/ycc/) — generated Codex plugin root
- [`.codex-plugin/agents/`](.codex-plugin/agents/) — generated Codex custom agents
- [`.agents/plugins/marketplace.json`](.agents/plugins/marketplace.json) — repo-local marketplace source for development

### Regenerate opencode skills, agents, commands, and plugin metadata

`ycc/skills/`, `ycc/agents/`, and `ycc/commands/` are the **source of truth**. After editing any of them, regenerate the opencode artifacts and validate:

```bash
./scripts/generate-opencode-skills.sh
./scripts/generate-opencode-agents.sh
./scripts/generate-opencode-commands.sh
./scripts/generate-opencode-plugin.sh
./scripts/validate-opencode-skills.sh
./scripts/validate-opencode-agents.sh
./scripts/validate-opencode-commands.sh
./scripts/validate-opencode-plugin.sh
```

opencode output layout:

- [`.opencode-plugin/skills/`](.opencode-plugin/skills/) — generated opencode skills
- [`.opencode-plugin/agents/`](.opencode-plugin/agents/) — generated opencode agents
- [`.opencode-plugin/commands/`](.opencode-plugin/commands/) — generated opencode slash commands
- [`.opencode-plugin/opencode.json`](.opencode-plugin/opencode.json) — config with `$schema`, default model, reasoning effort, translated MCP
- [`.opencode-plugin/AGENTS.md`](.opencode-plugin/AGENTS.md) — rules file (transformed from CLAUDE.md)
- [`.opencode-plugin/shared/`](.opencode-plugin/shared/) — infrastructure scripts referenced from skills
- [`scripts/opencode_model_aliases.json`](scripts/opencode_model_aliases.json) — Claude-shorthand → `openai/gpt-5.4`-family mapping; override per-user via `scripts/opencode_model_aliases.local.json`.

## Repository layout

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json     # marketplace registry (single ycc entry)
├── .agents/
│   └── plugins/
│       └── marketplace.json # repo-local Codex marketplace source
├── .codex-plugin/
│   ├── agents/              # generated Codex custom agents (.toml)
│   └── ycc/                 # generated Codex plugin root
│       ├── .codex-plugin/
│       │   └── plugin.json
│       ├── .mcp.json
│       ├── shared/
│       └── skills/
├── .cursor-plugin/            # Cursor IDE bundle (synced by install.sh --target cursor)
│   ├── agents/                # generated from ycc/agents (run scripts/generate-cursor-agents.sh)
│   ├── rules/                 # generated from ycc/rules (run scripts/generate-cursor-rules.sh)
│   └── skills/                # generated from ycc/skills (run scripts/generate-cursor-skills.sh)
├── .opencode-plugin/          # opencode bundle (synced by install.sh --target opencode)
│   ├── agents/                # generated from ycc/agents
│   ├── commands/              # generated from ycc/commands
│   ├── skills/                # generated from ycc/skills
│   ├── shared/                # generated from ycc/skills/_shared
│   ├── AGENTS.md              # generated rules file (transformed from CLAUDE.md)
│   └── opencode.json          # generated config: $schema + default model + MCP
├── mcp-configs/
│   └── mcp.json               # shared MCP servers; merged/copied by install.sh
├── install.sh                 # sync Claude/Cursor/Codex/opencode targets
├── scripts/
│   ├── generate-codex-skills.sh    # wrapper → generate_codex_skills.py
│   ├── generate_codex_skills.py    # ycc/skills → .codex-plugin/ycc/skills
│   ├── validate-codex-skills.sh    # sync check + Codex skill lint/content policy
│   ├── generate-codex-agents.sh    # wrapper → generate_codex_agents.py
│   ├── generate_codex_agents.py    # ycc/agents → .codex-plugin/agents
│   ├── validate-codex-agents.sh    # sync check + TOML/content policy
│   ├── generate-codex-plugin.sh    # wrapper → generate_codex_plugin.py
│   ├── generate_codex_plugin.py    # plugin manifest + repo-local marketplace metadata
│   ├── validate-codex-plugin.sh    # JSON + sync check
│   ├── generate-cursor-agents.sh   # wrapper → generate_cursor_agents.py
│   ├── generate_cursor_agents.py   # ycc/agents → .cursor-plugin/agents
│   ├── validate-cursor-agents.sh   # sync check + content policy
│   ├── generate-cursor-skills.sh   # wrapper → generate_cursor_skills.py
│   ├── generate_cursor_skills.py   # ycc/skills → .cursor-plugin/skills
│   ├── validate-cursor-skills.sh   # sync check + content policy
│   ├── generate-cursor-rules.sh    # wrapper → generate_cursor_rules.py
│   ├── generate_cursor_rules.py    # ycc/rules → .cursor-plugin/rules (.md → .mdc)
│   ├── validate-cursor-rules.sh    # sync + frontmatter lint + content policy
│   ├── generate-opencode-skills.sh    # wrapper → generate_opencode_skills.py
│   ├── generate_opencode_skills.py    # ycc/skills → .opencode-plugin/skills
│   ├── validate-opencode-skills.sh    # sync check + frontmatter lint + content policy
│   ├── generate-opencode-agents.sh    # wrapper → generate_opencode_agents.py
│   ├── generate_opencode_agents.py    # ycc/agents → .opencode-plugin/agents
│   ├── validate-opencode-agents.sh    # sync check + frontmatter lint + content policy
│   ├── generate-opencode-commands.sh  # wrapper → generate_opencode_commands.py
│   ├── generate_opencode_commands.py  # ycc/commands → .opencode-plugin/commands
│   ├── validate-opencode-commands.sh  # sync check + frontmatter lint + content policy
│   ├── generate-opencode-plugin.sh    # wrapper → generate_opencode_plugin.py
│   ├── generate_opencode_plugin.py    # opencode.json + AGENTS.md + MCP translation
│   ├── validate-opencode-plugin.sh    # JSON schema + sync check
│   ├── generate_opencode_common.py    # shared paths / transforms / model + tool maps
│   └── opencode_model_aliases.json    # Claude-shorthand → openai/gpt-5.4-family map
├── ycc/                       # the consolidated Claude Code plugin
│   ├── .claude-plugin/
│   │   └── plugin.json        # name: "ycc", current version in plugin.json
│   ├── commands/              # slash commands (count in generated region above)
│   ├── agents/                # agents (source for Cursor/Codex/opencode generation)
│   ├── rules/                 # language-specific rules (common + per-language); source for Cursor .mdc generation
│   ├── settings/              # shared Claude settings: settings.json, hooks/, rules/, statusline
│   └── skills/                # skills + _shared (source for Cursor/Codex/opencode generation)
│       ├── _shared/           # shared scripts (e.g., resolve-plans-dir.sh)
│       └── {skill-name}/
│           ├── SKILL.md
│           ├── references/    # templates and examples
│           └── scripts/       # validation and helpers
└── docs/
    └── plans/                 # implementation plans
```

## License

[MIT](LICENSE)
