---
name: init
description: This skill should be used when the user asks to "initialize workspace", "init project", "bootstrap CLAUDE.md", "generate AGENTS.md", "set up cursor rules", "add github issue templates", "add conventional commits config", "configure agents and MCPs for project", or any workspace/project initialization request. Profiles the project, emits the AI-agent doc trio (CLAUDE.md, AGENTS.md, .cursor/rules/project.mdc), and optionally GitHub templates and git conventions.
argument-hint: '[--dry-run] [--docs-only] [--templates] [--git] [--vendor-neutral] [--update] [--force] [--profile=rust|ts-node|python|go|mixed|empty]'
disable-model-invocation: true
allowed-tools:
  - Read
  - Grep
  - Glob
  - Write
  - Edit
  - Bash(ls:*)
  - Bash(cat:*)
  - Bash(cp:*)
  - Bash(mkdir:*)
  - Bash(diff:*)
  - Bash(jq:*)
  - 'Bash(${HOME}/.cursor/mcp-library/generate-mcp-config.sh:*)'
  - 'Bash(${CURSOR_PLUGIN_ROOT}/skills/init/scripts/*.sh:*)'
---

# Cursor CLI Workspace Initialization

Profiles the project, authors the AI-agent doc trio (CLAUDE.md, AGENTS.md, .cursor/rules/project.mdc), and optionally emits GitHub issue templates and git convention files — all flag-driven, non-destructive by default.

## Current Project Context

- **Working Directory**: !`pwd`
- **Project Files**: !`ls -la 2>/dev/null | head -25`
- **Profile detection**: !`${CURSOR_PLUGIN_ROOT}/skills/init/scripts/profile-project.sh 2>/dev/null | head -20`

## Arguments

| Flag               | Meaning                                                                          | Example                      |
| ------------------ | -------------------------------------------------------------------------------- | ---------------------------- |
| `--dry-run`        | Preview every planned file; make no writes                                       | `/init --dry-run`        |
| `--docs-only`      | Skip MCP/agent selection; emit doc trio only                                     | `/init --docs-only`      |
| `--templates`      | Also emit `.github/` issue forms, PR template, labels                            | `/init --templates`      |
| `--git`            | Also emit `.gitmessage` and commitlint config (JS/TS)                            | `/init --git`            |
| `--vendor-neutral` | Also emit `.ai/rules/project.md` mirror of Cursor rule                           | `/init --vendor-neutral` |
| `--update`         | Structured refresh of existing artifacts (merge/migrate, never clobber)          | `/init --update`         |
| `--force`          | Overwrite existing files without prompting                                       | `/init --force`          |
| `--profile=<lang>` | Override detected language (`rust`, `ts-node`, `python`, `go`, `mixed`, `empty`) | `/init --profile=rust`   |

Flags are composable. See `references/flag-reference.md` for the full matrix.

## Task

Execute the following phases in order. Phases are short — do not add narrative prose between steps.

### Phase 0 — Parse flags

Extract mode booleans from `$ARGUMENTS`:

- `DRY_RUN` — true if `--dry-run` present
- `DOCS_ONLY` — true if `--docs-only` present
- `TEMPLATES` — true if `--templates` present
- `GIT` — true if `--git` present
- `VENDOR_NEUTRAL` — true if `--vendor-neutral` present
- `UPDATE` — true if `--update` present
- `FORCE` — true if `--force` present
- `PROFILE` — value of `--profile=<lang>` if provided, else empty

Defaults: all booleans off; no profile override. `--update` and `--force` are mutually reinforcing: `--update` controls merge/migrate behavior, `--force` controls conflict resolution. Without either, existing files are preserved with a diff-and-ask prompt.

### Phase 1 — Profile

1. Run `${CURSOR_PLUGIN_ROOT}/skills/init/scripts/profile-project.sh` and parse the `key=value` output into variables. See `references/project-profile-heuristics.md` for the key list.
2. If `PROFILE` flag is set, override `primary_language` with that value.
3. If `is_empty=true` OR `primary_language=unknown`: ask the user conversationally for project name, purpose, and primary language. Set `project_name`, `project_purpose`, and `primary_language` from their answers.
4. If `UPDATE=false` AND at least two of `has_claude_md`, `has_agents_md`, `has_cursor_rules`, `has_issue_templates`, `has_gitmessage` are true: warn the user "Existing doc/workflow files detected — consider re-running with `--update` for structured refresh, or `--force` to overwrite. Continuing with default skip-on-conflict behavior."
5. Surface the resolved profile summary to the user and wait for confirmation before writing anything — except when `DRY_RUN=true`, which proceeds directly to preview.

### Phase 2 — Optional deep analysis

Skip this phase when `DOCS_ONLY=true`.

Otherwise, estimate source file count:

```bash
find . -type f | head -n 51 | wc -l
```

If count is 51 (i.e., >50 files), dispatch `subagent_type: "codebase-research-analyst"` with a prompt requesting:

- Key architectural patterns and conventions to encode in `CLAUDE.md`
- Critical commands (test, lint, build, deploy) to embed
- Project-specific MUST/MUST NOT rules worth adding

Feed the agent's output into the CLAUDE.md rendering in Phase 3.

### Phase 3 — Render templates

Load each applicable `.tmpl` file from `${CURSOR_PLUGIN_ROOT}/skills/init/templates/`. Substitute all `{{PLACEHOLDER}}` variables using profile values from Phase 1 (and Phase 2 if run). For language-conditional blocks (`{{#IF_RUST}}...{{/IF_RUST}}` etc.), include only the block matching `primary_language`. Render all files in memory — do NOT write yet.

Rendering map:

| Condition                                                      | Source template                         | Target path                                  |
| -------------------------------------------------------------- | --------------------------------------- | -------------------------------------------- |
| Always                                                         | `CLAUDE.md.tmpl`                        | `CLAUDE.md`                                  |
| Always                                                         | `AGENTS.md.tmpl`                        | `AGENTS.md`                                  |
| Always                                                         | `cursor-rule.mdc.tmpl`                  | `.cursor/rules/project.mdc`                  |
| `VENDOR_NEUTRAL=true`                                          | `ai-rule.md.tmpl`                       | `.ai/rules/project.md`                       |
| `TEMPLATES=true`                                               | `github/bug_report.yml.tmpl`            | `.github/ISSUE_TEMPLATE/bug_report.yml`      |
| `TEMPLATES=true`                                               | `github/feature_request.yml.tmpl`       | `.github/ISSUE_TEMPLATE/feature_request.yml` |
| `TEMPLATES=true`                                               | `github/docs_request.yml.tmpl`          | `.github/ISSUE_TEMPLATE/docs_request.yml`    |
| `TEMPLATES=true`                                               | `github/config.yml.tmpl`                | `.github/ISSUE_TEMPLATE/config.yml`          |
| `TEMPLATES=true`                                               | `github/pull_request_template.md.tmpl`  | `.github/pull_request_template.md`           |
| `TEMPLATES=true`                                               | `github/labels.md.tmpl`                 | `.github/labels.md`                          |
| `GIT=true`                                                     | `git/gitmessage.tmpl`                   | `.gitmessage`                                |
| `GIT=true`                                                     | `git/pre-commit-recommendation.md.tmpl` | `docs/pre-commit-recommendation.md`          |
| `GIT=true` AND `primary_language` in `{typescript,javascript}` | `git/commitlint.config.cjs.tmpl`        | `commitlint.config.cjs`                      |

See `references/template-library.md` for placeholder definitions.

### Phase 4 — MCP/agent selection

Skip this phase when `DOCS_ONLY=true`.

Run the catalog generators:

```bash
${CURSOR_PLUGIN_ROOT}/skills/init/scripts/generate-mcp-catalog.sh
${CURSOR_PLUGIN_ROOT}/skills/init/scripts/generate-agent-catalog.sh
```

Present all available options as checkboxes organized by category. Pre-check items that align with the detected profile (language, infrastructure, workflow). Let the user freely adjust the selection before proceeding.

### Phase 5 — Dry-run check

If `DRY_RUN=true`:

- Print a listing of every planned file with a preview snippet (first ~15 lines each).
- Show the planned `.mcp.json` content.
- List agent files that would be copied.
- STOP — make no writes.

### Phase 6 — Apply

For each rendered file from Phase 3, apply the resolution rule below. Never silently clobber user content.

**Target does not exist** → write the rendered file.

**Target exists AND `FORCE=true`** → overwrite and log the path.

**Target exists AND `UPDATE=true`** → structured refresh per artifact type:

| Artifact                                               | Update behavior                                                                                                                                                                                               |
| ------------------------------------------------------ | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `CLAUDE.md`                                            | Parse existing `##`-level section headings. Append any template sections that are missing. Preserve all existing content verbatim. Report the appended section list.                                          |
| `AGENTS.md` (pointer, `agents_md_is_pointer=true`)     | Refresh pointer boilerplate text. Preserve any user-authored content under `## Agent-runtime notes`.                                                                                                          |
| `AGENTS.md` (custom, `agents_md_is_pointer=false`)     | Ask the user: (a) migrate to pointer — preserve original content under `## Agent-runtime notes` and write canonical pointer, or (b) merge — append missing sections, keep existing content. Default: migrate. |
| `.cursor/rules/project.mdc`                            | Overwrite body content; preserve any non-standard frontmatter keys the user added beyond `description`, `globs`, `alwaysApply`.                                                                               |
| `.cursorrules` (legacy, `has_legacy_cursorrules=true`) | Migrate: read legacy content, write `.cursor/rules/project.mdc` (creating it if absent, merging otherwise), then advise the user to delete `.cursorrules` (do not delete automatically).                      |
| `.ai/rules/project.md`                                 | Same rule as `.cursor/rules/project.mdc` body.                                                                                                                                                                |
| `.github/ISSUE_TEMPLATE/*.yml`                         | Per template: if missing → create; if present → show diff and default to skip (issue forms are often customized). `--update --force` overwrites.                                                              |
| `.github/pull_request_template.md`                     | Show diff; default skip. `--update --force` overwrites.                                                                                                                                                       |
| `.github/labels.md`                                    | Always overwrite (reference doc, safe to refresh).                                                                                                                                                            |
| `.gitmessage`                                          | Show diff; default skip. `--update --force` overwrites (usually safe — it is a reference template).                                                                                                           |
| `commitlint.config.cjs`                                | If present → show diff and default skip with a warning ("commitlint rules are often project-customized"). `--update --force` overwrites.                                                                      |
| `docs/pre-commit-recommendation.md`                    | Always overwrite (advisory doc).                                                                                                                                                                              |

**Target exists AND `UPDATE=false` AND `FORCE=false`** → show a unified diff, then prompt the user with three choices: overwrite, merge (only meaningful for `CLAUDE.md`), or skip. Default choice: skip.

Then apply MCP/agent selections from Phase 4 (skipped when `DOCS_ONLY=true`):

```bash
${HOME}/.cursor/mcp-library/generate-mcp-config.sh <selected-mcps>
```

Create `.claude/agents/` if needed; copy selected agent files from `${HOME}/.cursor/agents/`.

### Phase 7 — Summary report

Produce a summary using `${CURSOR_PLUGIN_ROOT}/skills/init/templates/workspace-report.md` as the base. Extend it with these sections appended after the existing MCP/agents tables:

**Docs emitted** — list each path written, or "skipped: user chose keep".

**GitHub templates emitted** — list each `.github/` path written (omit section if `TEMPLATES=false`).

**Git conventions emitted** — list each git artifact path written (omit section if `GIT=false`).

**Next steps** — suggest:

- `git config commit.template .gitmessage` (if `GIT=true`)
- Review `.github/labels.md` and run the `gh label create` commands listed there (if `TEMPLATES=true`)
- Open `CLAUDE.md` to review and refine the generated project rules.
- If `has_legacy_cursorrules=true` and the migration ran: delete the legacy `.cursorrules` file once the new `.cursor/rules/project.mdc` is confirmed working.

## Important Notes

- Default behavior never destroys existing files; always diff-and-ask before overwriting.
- `--update` enables structured merge/migrate semantics and is the recommended flag when re-running `init` in a project that already has docs/templates.
- `--force` is opt-in and always logs every path it overwrote. `--update --force` applies merge semantics but overwrites on conflict instead of skipping.
- No new agents are registered. `codebase-research-analyst` is called only once, conditionally, for large existing repos (>50 source files) when `--docs-only` is not set.
- The MCP and agent selection flow is preserved unchanged behind `--docs-only`.
- For the full flag matrix with composability examples, see `references/flag-reference.md`.
