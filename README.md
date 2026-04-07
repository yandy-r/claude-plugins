# claude-plugins

A single Claude Code plugin (`ycc`) bundling workflow orchestration, parallel planning, documentation, research, and project management — all available under the `ycc:` namespace.

> **2.0.0 breaking change.** Versions ≤ 1.x shipped 9 separate plugins (`ask`, `plan-workflow`, `git-workflow`, `implement-plan`, `code-report`, `deep-research`, `orchestrate`, `write-docs`, `project`). 2.0.0 collapses all of them into a single `ycc` plugin so every skill is accessible via `ycc:{skill}`. Re-install after upgrading.

## What's inside

The `ycc` plugin ships **12 skills**, **9 slash commands**, and **9 agents**:

| Skill (`ycc:{skill}`)     | Slash command           | Purpose                                                                       |
| ------------------------- | ----------------------- | ----------------------------------------------------------------------------- |
| `ycc:ask-codebase`        | `/ycc:ask`              | Read-only codebase Q&A, impact analysis, and comparisons                      |
| `ycc:plan-workflow`       | —                       | Top-level orchestrator that runs the full feature-research → plan pipeline    |
| `ycc:feature-research`    | —                       | Feature research stage of the planning pipeline                               |
| `ycc:shared-context`      | —                       | Build shared context (files, conventions, dependencies) for downstream stages |
| `ycc:parallel-plan`       | —                       | Generate parallel implementation plans with task dependencies                 |
| `ycc:implement-plan`      | `/ycc:implement-plan`   | Execute parallel plans by deploying implementor agents in batches             |
| `ycc:code-report`         | `/ycc:code-report`      | Generate structured reports documenting implementation changes                |
| `ycc:git-workflow`        | `/ycc:git-workflow`     | Commit strategy, conventional messages, docs updates, PR creation             |
| `ycc:research-to-issues`  | `/ycc:research-to-issues` | Convert deep-research output into structured GitHub issues                  |
| `ycc:orchestrate`         | —                       | Decompose complex tasks into parallel specialized agent executions            |
| `ycc:deep-research`       | `/ycc:deep-research`    | 8-persona Asymmetric Research Squad for multi-perspective analysis            |
| `ycc:write-docs`          | `/ycc:write-docs`       | 5 parallel documentation agents: API, architecture, code, features, README   |
| `ycc:init-workspace`      | `/ycc:init`             | Workspace initialization with project analysis                                |
| `ycc:project-cleaner`     | `/ycc:clean`            | Parallel cleanup with comprehensive safety measures                           |

### Agents

`ycc:codebase-advisor`, `ycc:feature-researcher`, `ycc:practices-researcher`, `ycc:project-file-cleaner`, `ycc:api-documenter`, `ycc:architecture-analyst`, `ycc:code-documenter`, `ycc:feature-writer`, `ycc:readme-generator`

## Installation

```bash
# Add the marketplace
/plugin marketplace add yandy-r/claude-plugins

# Install the bundle
/plugin install ycc@yandy-plugins
```

Or enable in `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "ycc@yandy-plugins": true
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

## Repository layout

```
claude-plugins/
├── .claude-plugin/
│   └── marketplace.json     # marketplace registry (single ycc entry)
├── ycc/                     # the consolidated plugin
│   ├── .claude-plugin/
│   │   └── plugin.json      # name: "ycc", version: 2.0.0
│   ├── commands/            # 9 slash commands
│   ├── agents/              # 9 agents
│   └── skills/              # 12 skills + _shared
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
