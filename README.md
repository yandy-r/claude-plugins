# claude-plugins

A single Claude Code plugin (`ycc`) bundling workflow orchestration, parallel planning, documentation, research, and project management. The repository also generates native compatibility bundles for Cursor, Codex, and opencode.

> **2.0.0 breaking change.** Versions ≤ 1.x shipped 9 separate plugins (`ask`, `plan-workflow`, `git-workflow`, `implement-plan`, `code-report`, `deep-research`, `orchestrate`, `write-docs`, `project`). 2.0.0 collapses all of them into a single `ycc` plugin so every skill is accessible via `ycc:{skill}`. Re-install after upgrading.

## What's inside

<!-- BEGIN:GENERATED-COUNTS -->

The source plugin ships **47 skills**, **46 slash commands** (most skills have a matching command), and **53 agents**.

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
| `/ycc:deep-research`       | Conduct strategic multi-perspective research using the Asymmetric Research Squad methodology — 8 specialized personas (historical, contrarian, analogical, systems, journalistic, ar... |
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
| `/ycc:pr-autofix`          | Vendor-neutral PR comment auto-fix — discover every review thread, file-level review comment, and top-level PR comment from any author, dispatch per-comment fix agents, resolve thr... |
| `/ycc:prp-commit`          | Quick natural-language git commit helper — describe what to commit in plain English (blob glob, filter phrase, or topic).                                                               |
| `/ycc:prp-implement`       | Execute a PRP plan file with per-task validation loops.                                                                                                                                 |
| `/ycc:prp-plan`            | Create a single-pass implementation plan from a feature description or PRD.                                                                                                             |
| `/ycc:prp-pr`              | Create a GitHub PR from the current branch — discovers templates, analyzes commits, references PRP artifacts, pushes, and opens the PR via gh.                                          |
| `/ycc:prp-prd`             | Interactive PRD generator — problem-first, hypothesis-driven product spec built through iterative questioning and dual-mode grounding research.                                         |
| `/ycc:prp-spec`            | Generate a lightweight feature spec for the PRP workflow — single-pass with optional codebase/market grounding.                                                                         |
| `/ycc:python-patterns`     | Idiomatic Python patterns, PEP 8 conventions, type hints, dataclasses, context managers, decorators, and best practices for building robust, maintainable Python applications.          |
| `/ycc:python-testing`      | Python testing patterns using pytest — TDD methodology, fixtures (function/module/session scopes), parametrization, markers, mocking with unittest.mock, async tests with pytest-asy... |
| `/ycc:quick-fix`           | Apply fixes from an inline /ycc:quick-review findings block without creating a review artifact.                                                                                         |
| `/ycc:quick-review`        | Fast interactive review of uncommitted changes.                                                                                                                                         |
| `/ycc:releaser`            | Prepare and cut a GitHub release for any project — detects toolchain, drafts changelog, plans platform/arch artifacts, optionally generates or audits release CI.                       |
| `/ycc:research-to-issues`  | Convert research, feature specs, and implementation plans into structured GitHub issues with tracking hierarchy, labels, and priority.                                                  |
| `/ycc:resume-session`      | Load the most recent session file from ~/.claude/session-data/ and resume work with full context.                                                                                       |
| `/ycc:review-fix`          | Plan and apply fixes for findings from a /ycc:code-review artifact.                                                                                                                     |
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

The plugin bundles **53** specialized agents covering codebase analysis, language experts (Go, Rust, Python, TypeScript), reviewers, planners, documenters, and infrastructure architects.

<details>
<summary>Full agent list (53 agents, grouped by role)</summary>

- **Language experts & implementors** (12): `frontend-ui-developer`, `go-api-architect`, `go-expert-architect`, `nextjs-ux-ui-expert`, `nodejs-backend-architect`, `nodejs-backend-developer`, `python-developer`, `python-expert-architect`, `rust-build-resolver`, `rust-expert-architect`, `typescript-developer`, `typescript-expert-architect`
- **Code review & quality** (5): `code-reviewer`, `code-simplifier`, `pr-comment-fixer`, `review-fixer`, `rust-reviewer`
- **Research & discovery** (10): `code-explorer`, `code-finder`, `code-researcher`, `codebase-advisor`, `feature-researcher`, `library-docs-writer`, `practices-researcher`, `prp-researcher`, `research-specialist`, `root-cause-analyzer`
- **Architecture & planning** (5): `architect`, `architecture-analyst`, `code-architect`, `planner`, `test-strategy-planner`
- **Documentation** (7): `api-docs-expert`, `api-documenter`, `code-documenter`, `docs-git-committer`, `documentation-writer`, `feature-writer`, `readme-generator`
- **Infrastructure & DevOps** (7): `ansible-automation-expert`, `cloudflare-architect`, `cloudflare-developer`, `reverse-proxy-architect`, `systems-engineering-expert`, `terraform-architect`, `terraform-developer`
- **Databases** (3): `db-modifier`, `sql-database-developer`, `turso-database-architect`
- **Workflow utilities** (4): `git-cleanup`, `implementor`, `project-file-cleaner`, `releaser`

</details>

<!-- END:GENERATED-AGENTS -->

- **Claude Code:** reference any of them via `subagent_type: "ycc:{agent-name}"`. Canonical source lives in [`ycc/agents/`](ycc/agents/).
- **Cursor:** generated, Cursor-native copies live in [`.cursor-plugin/agents/`](.cursor-plugin/agents/) (produced from `ycc/agents/` — see the [Cursor install guide](docs/install/cursor.md)).
- **Codex:** generated, Codex-native custom-agent TOMLs live in [`.codex-plugin/agents/`](.codex-plugin/agents/) (produced from `ycc/agents/` — see the [Codex install guide](docs/install/codex.md)).
- **opencode:** generated, opencode-native agent markdown files live in [`.opencode-plugin/agents/`](.opencode-plugin/agents/) (produced from `ycc/agents/` — see the [opencode install guide](docs/install/opencode.md)). Invoke via `@agent-name` mention or the built-in `task` tool.

**Contributing:** before proposing a new skill, command, or agent, read the Scope & Guardrails policy in [`CONTRIBUTING.md`](CONTRIBUTING.md#scope--guardrails).

## Installation

For Claude Code, install the published `ycc` plugin from the marketplace:

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

For local development installs, generated compatibility bundles, and desktop app
notes, use the dedicated install guides:

| Runtime                      | Install guide                                          |
| ---------------------------- | ------------------------------------------------------ |
| Claude Code / Claude Desktop | [`docs/install/claude.md`](docs/install/claude.md)     |
| Cursor                       | [`docs/install/cursor.md`](docs/install/cursor.md)     |
| Codex / Codex Desktop        | [`docs/install/codex.md`](docs/install/codex.md)       |
| opencode                     | [`docs/install/opencode.md`](docs/install/opencode.md) |
| Shared installer concepts    | [`docs/install/README.md`](docs/install/README.md)     |

## Workflow composition

The planning skills compose into a pipeline:

```
ycc:feature-research → ycc:shared-context → ycc:parallel-plan → ycc:implement-plan → ycc:code-report → ycc:git-workflow
   (research)            (gather files)       (design tasks)      (deploy agents)      (document)         (commit/PR)
```

Use `ycc:plan-workflow` to run the full pipeline, or invoke individual stages.

## Development Sync

This repository maintains generated compatibility trees under **`.cursor-plugin/`**,
**`.codex-plugin/`**, and **`.opencode-plugin/`**. The canonical source of truth
is the Claude-facing [`ycc/`](ycc/) tree.

Regenerate and validate derived artifacts with:

```bash
./scripts/sync.sh        # regenerate inventory and compatibility bundles
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
    ├── install/               # runtime-specific install guides
    └── plans/                 # implementation plans
```

## License

[MIT](LICENSE)
