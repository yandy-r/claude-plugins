# claude-plugins

A single Claude Code plugin (`ycc`) bundling workflow orchestration, parallel planning, documentation, research, and project management. The repository also generates native compatibility bundles for Cursor and Codex.

> **2.0.0 breaking change.** Versions ≤ 1.x shipped 9 separate plugins (`ask`, `plan-workflow`, `git-workflow`, `implement-plan`, `code-report`, `deep-research`, `orchestrate`, `write-docs`, `project`). 2.0.0 collapses all of them into a single `ycc` plugin so every skill is accessible via `ycc:{skill}`. Re-install after upgrading.

## What's inside

The source plugin ships **34 skills**, **34 slash commands** (1-to-1 with skills), and **50 agents**.

| Command / Skill           | Purpose                                                                    |
| ------------------------- | -------------------------------------------------------------------------- |
| `/ycc:ask`                | Read-only codebase Q&A, impact analysis, and comparisons                   |
| `/ycc:clean`              | Parallel cleanup agents with comprehensive safety measures                 |
| `/ycc:code-report`        | Structured implementation reports after plan execution                     |
| `/ycc:code-review`        | Local diff or PR review with security + quality checks                     |
| `/ycc:deep-research`      | 8-persona Asymmetric Research Squad for multi-perspective analysis         |
| `/ycc:feature-research`   | Feature research stage of the planning pipeline                            |
| `/ycc:frontend-design`    | Distinctive, production-grade UI design direction                          |
| `/ycc:frontend-patterns`  | React/Next.js patterns: composition, hooks, performance, accessibility     |
| `/ycc:frontend-slides`    | Animation-rich, zero-dependency HTML presentations                         |
| `/ycc:git-workflow`       | Commit strategy, conventional messages, docs updates, PR creation          |
| `/ycc:go-patterns`        | Idiomatic Go: errors, goroutines, interfaces, package design               |
| `/ycc:go-testing`         | Go table-driven tests, subtests, benchmarks, fuzzing                       |
| `/ycc:implement-plan`     | Execute parallel plans by deploying implementor agents in batches          |
| `/ycc:init`               | Workspace initialization with project analysis                             |
| `/ycc:orchestrate`        | Decompose complex tasks into parallel specialized agent executions         |
| `/ycc:parallel-plan`      | Generate parallel implementation plans with task dependencies              |
| `/ycc:plan`               | Lightweight conversational planner with confirmation gates                 |
| `/ycc:plan-workflow`      | Top-level orchestrator running the full feature-research → plan pipeline   |
| `/ycc:prp-commit`         | Natural-language git commit helper                                         |
| `/ycc:prp-implement`      | PRP plan executor with per-task validation loops                           |
| `/ycc:prp-plan`           | Single-pass implementation plan from a feature description or PRD          |
| `/ycc:prp-pr`             | Create a GitHub PR from the current branch with PRP context                |
| `/ycc:prp-prd`            | Interactive problem-first PRD generator                                    |
| `/ycc:python-patterns`    | Idiomatic Python: type hints, dataclasses, decorators, asyncio             |
| `/ycc:python-testing`     | pytest fixtures, parametrize, mocking, async tests, coverage               |
| `/ycc:research-to-issues` | Convert deep-research output into structured GitHub issues                 |
| `/ycc:resume-session`     | Load most recent saved session and resume with full context                |
| `/ycc:rust-patterns`      | Idiomatic Rust: ownership, traits, error handling, async                   |
| `/ycc:rust-testing`       | Rust unit/integration tests with rstest, proptest, mockall                 |
| `/ycc:save-session`       | Save current session state to a dated file for later resume                |
| `/ycc:shared-context`     | Build shared context (files, conventions, dependencies) for planning       |
| `/ycc:ts-patterns`        | Idiomatic TypeScript: strict types, generics, ESM/CJS, runtime selection   |
| `/ycc:ts-testing`         | Vitest unit/integration, fake timers, mocking, type-level tests            |
| `/ycc:write-docs`         | 5 parallel documentation agents: API, architecture, code, features, README |

### Agents

The plugin bundles **50** specialized agents covering codebase analysis, language experts (Go, Rust, Python, TypeScript), reviewers, planners, documenters, and infrastructure architects.

- **Claude Code:** reference any of them via `subagent_type: "ycc:{agent-name}"`. Canonical source lives in [`ycc/agents/`](ycc/agents/).
- **Cursor:** generated, Cursor-native copies live in [`.cursor-plugin/agents/`](.cursor-plugin/agents/) (produced from `ycc/agents/` — see [Cursor IDE sync](#cursor-ide-sync)).
- **Codex:** generated, Codex-native custom-agent TOMLs live in [`.codex-plugin/agents/`](.codex-plugin/agents/) (produced from `ycc/agents/` and synced to `~/.codex/agents/` by `install.sh --target codex`).

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

Cursor loads **skills**, **agents**, and **rules** from `~/.cursor/{skills,agents,rules}/`. Codex uses a **plugin** for skills/MCP plus **custom agents** in `~/.codex/agents/`. This repository maintains generated compatibility trees under **`.cursor-plugin/`** and **`.codex-plugin/`**.

Shared MCP server definitions live in [`mcp-configs/mcp.json`](mcp-configs/mcp.json). The installer adapts them per target:

| Target   | What it does |
| -------- | ------------ |
| `claude` | Merges `mcpServers` from `mcp-configs/mcp.json` into **user-scoped** `~/.claude.json` (preserves other keys such as `projects`). |
| `cursor` | Generates and validates the Cursor bundle, rsyncs `skills/`, `agents/`, and `rules/` into `~/.cursor/`, then copies MCP config to `~/.cursor/mcp.json`. |
| `codex`  | Generates and validates a Codex-native plugin in `.codex-plugin/ycc/`, syncs it to `~/.codex/plugins/ycc/`, syncs generated custom agents to `~/.codex/agents/`, and merges a `ycc` entry into `~/.agents/plugins/marketplace.json`. |
| `all`    | Runs the `claude`, `cursor`, and `codex` pipelines. |

### Install targets

```bash
./install.sh --target cursor    # bundle + ~/.cursor/mcp.json
./install.sh --target claude    # ~/.claude.json merge only
./install.sh --target codex     # plugin source + ~/.codex/agents + ~/.agents/plugins/marketplace.json
./install.sh --target all       # claude + cursor + codex
```

The `cursor` target rsyncs `.cursor-plugin/skills/`, `.cursor-plugin/agents/`, and `.cursor-plugin/rules/` into `~/.cursor/` (see [`install.sh`](install.sh) for behavior when a source unit is missing), then installs `mcp-configs/mcp.json` as `~/.cursor/mcp.json`.

The `codex` target syncs:

- plugin source: [`.codex-plugin/ycc/`](.codex-plugin/ycc/) → `~/.codex/plugins/ycc/`
- native custom agents: [`.codex-plugin/agents/`](.codex-plugin/agents/) → `~/.codex/agents/`
- user marketplace entry: `~/.agents/plugins/marketplace.json`

After running the Codex target, restart Codex, open `/plugins`, and install `ycc` from your local marketplace if it is not already installed.

### Codex notes

- Codex support is **native**, not a Cursor-style copy. Skills are packaged as a Codex plugin and agents are emitted as Codex custom-agent TOMLs.
- Codex does **not** support this repo's custom slash-command layer as installable artifacts. Use the bundled skills directly with `$skill-name` or by invoking the installed `ycc` plugin, and use Codex built-ins such as `/plan` and `/review` where applicable.
- Generated Codex skill references assume the managed install location `~/.codex/plugins/ycc/` for bundled helper scripts and references.

### Regenerate Cursor agents

`ycc/agents/*.md` is the **source of truth**. After editing an agent there, regenerate the Cursor copies and validate:

```bash
./scripts/generate-cursor-agents.sh
./scripts/validate-cursor-agents.sh
```

The generator **overwrites** each matching `*.md` and **deletes** any `*.md` under `.cursor-plugin/agents/` that no longer exists in `ycc/agents/`, so the two trees stay in lockstep.

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
├── mcp-configs/
│   └── mcp.json               # shared MCP servers; merged/copied by install.sh
├── install.sh                 # sync Claude/Cursor/Codex targets
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
│   └── validate-cursor-rules.sh    # sync + frontmatter lint + content policy
├── ycc/                       # the consolidated Claude Code plugin
│   ├── .claude-plugin/
│   │   └── plugin.json        # name: "ycc", version: 2.0.0
│   ├── commands/              # 34 slash commands
│   ├── agents/                # 50 agents (source for Cursor/Codex generation)
│   ├── rules/                 # language-specific rules (common + per-language); source for Cursor .mdc generation
│   └── skills/                # 34 skills + _shared (source for Cursor generation)
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
