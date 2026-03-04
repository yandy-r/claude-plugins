# claude-plugins

A collection of Claude Code plugins for workflow orchestration, parallel planning, documentation, research, and project management.

## Plugin Catalog

| Plugin             | Description                                                                | Commands                                                                   |
| ------------------ | -------------------------------------------------------------------------- | -------------------------------------------------------------------------- |
| **ask**            | Read-only codebase advisor for Q&A, impact analysis, and comparisons       | `/ask-codebase`                                                            |
| **plan-workflow**  | Unified planning pipeline: research, context, parallel plans, validation   | `/plan-workflow`, `/feature-research`, `/shared-context`, `/parallel-plan` |
| **implement-plan** | Execute parallel plans by deploying implementor agents in batches          | `/implement-plan`                                                          |
| **code-report**    | Generate structured reports documenting implementation changes             | `/code-report`                                                             |
| **git-workflow**   | Commit strategy, conventional messages, docs updates, PR creation          | `/git-workflow`                                                            |
| **orchestrate**    | Decompose complex tasks into parallel specialized agent executions         | `/orchestrate`                                                             |
| **deep-research**  | 8-persona Asymmetric Research Squad for multi-perspective analysis         | `/deep-research`                                                           |
| **write-docs**     | 5 parallel documentation agents: API, architecture, code, features, README | `/write-docs`                                                              |
| **project**        | Workspace initialization and parallel cleanup with safety measures         | `/init-workspace`, `/project-cleaner`                                      |

## Installation

```bash
# Add the marketplace
/plugin marketplace add yandy-r/claude-plugins

# Enable a specific plugin
/plugin install ask@yandy-plugins
/plugin install plan-workflow@yandy-plugins
```

Or enable all plugins at once in `~/.claude/settings.json`:

```json
{
  "enabledPlugins": {
    "ask@yandy-plugins": true,
    "plan-workflow@yandy-plugins": true,
    "implement-plan@yandy-plugins": true,
    "code-report@yandy-plugins": true,
    "git-workflow@yandy-plugins": true,
    "orchestrate@yandy-plugins": true,
    "deep-research@yandy-plugins": true,
    "write-docs@yandy-plugins": true,
    "project@yandy-plugins": true
  }
}
```

## Workflow Composition

The planning plugins compose into a pipeline:

```
feature-research  ->  shared-context  ->  parallel-plan  ->  implement-plan  ->  code-report  ->  git-workflow
    (research)         (gather files)     (design tasks)    (deploy agents)    (document)       (commit/PR)
```

Use `/plan-workflow` to run the full pipeline, or invoke individual steps.

## Plugin Architecture

Each plugin follows a standard structure:

```
plugin-name/
  .claude-plugin/
    plugin.json          # Plugin manifest
  commands/              # Slash command definitions
  skills/                # Skill definitions with SKILL.md
    skill-name/
      SKILL.md           # Skill prompt and configuration
      references/        # Reference templates and examples
      scripts/           # Validation and helper scripts
  agents/                # Agent definitions (.md files)
  scripts/               # Shared plugin scripts
```

## License

[MIT](LICENSE)
