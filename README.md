# claude-plugins

A single Claude Code plugin (`ycc`) bundling workflow orchestration, parallel planning, documentation, research, and project management — all available under the `ycc:` namespace.

> **2.0.0 breaking change.** Versions ≤ 1.x shipped 9 separate plugins (`ask`, `plan-workflow`, `git-workflow`, `implement-plan`, `code-report`, `deep-research`, `orchestrate`, `write-docs`, `project`). 2.0.0 collapses all of them into a single `ycc` plugin so every skill is accessible via `ycc:{skill}`. Re-install after upgrading.

## What's inside

The `ycc` plugin ships **34 skills**, **34 slash commands** (1-to-1 with skills), and **43 agents**. Every skill is reachable as either `ycc:{name}` (auto-trigger) or `/ycc:{name}` (explicit invocation).

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

The plugin bundles 43 specialized agents covering codebase analysis, language experts (Go, Rust, Python, TypeScript), reviewers, planners, documenters, and infrastructure architects. Reference any of them via `subagent_type: "ycc:{agent-name}"`. See `ycc/agents/` for the full list.

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

## Cursor IDE sync

The install script syncs skills, agents, and rules to your Cursor config directory:

```bash
./install.sh --target cursor
```

This rsyncs `ycc/skills/`, `ycc/agents/`, and `ycc/rules/` into `~/.cursor/`. Existing files at the destination are preserved; only newer source files overwrite.

## Repository layout

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json     # marketplace registry (single ycc entry)
├── install.sh               # sync assets to IDE config directories
├── ycc/                     # the consolidated plugin
│   ├── .claude-plugin/
│   │   └── plugin.json      # name: "ycc", version: 2.0.0
│   ├── commands/            # 34 slash commands
│   ├── agents/              # 43 agents
│   ├── rules/               # language-specific rules (common + per-language)
│   └── skills/              # 34 skills + _shared
│       ├── _shared/         # shared scripts (e.g., resolve-plans-dir.sh)
│       └── {skill-name}/
│           ├── SKILL.md
│           ├── references/  # templates and examples
│           └── scripts/     # validation and helpers
└── docs/
    └── plans/               # implementation plans
```

## License

[MIT](LICENSE)
