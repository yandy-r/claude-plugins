# Template Library

Every template the skill can render, its target path, and the variables it substitutes.

---

## Template Catalog

| Template file                                    | Output path                                    | Gating flag          | Placeholders used                                                                      |
| ------------------------------------------------ | ---------------------------------------------- | -------------------- | -------------------------------------------------------------------------------------- |
| `templates/CLAUDE.md.tmpl`                       | `./CLAUDE.md`                                  | _(default)_          | `PROJECT_NAME`, `PRIMARY_LANG`, `TEST_CMD`, `LINT_CMD`, `BUILD_CMD`, `PROJECT_PURPOSE` |
| `templates/AGENTS.md.tmpl`                       | `./AGENTS.md`                                  | _(default)_          | `PROJECT_NAME`                                                                         |
| `templates/cursor-rule.mdc.tmpl`                 | `./.cursor/rules/project.mdc`                  | _(default)_          | `PROJECT_NAME`, `PRIMARY_LANG`                                                         |
| `templates/ai-rule.md.tmpl`                      | `./.ai/rules/project.md`                       | `--vendor-neutral`   | `PROJECT_NAME`, `PRIMARY_LANG`                                                         |
| `templates/github/bug_report.yml.tmpl`           | `./.github/ISSUE_TEMPLATE/bug_report.yml`      | `--templates`        | `PROJECT_NAME`                                                                         |
| `templates/github/feature_request.yml.tmpl`      | `./.github/ISSUE_TEMPLATE/feature_request.yml` | `--templates`        | `PROJECT_NAME`                                                                         |
| `templates/github/docs_request.yml.tmpl`         | `./.github/ISSUE_TEMPLATE/docs_request.yml`    | `--templates`        | `PROJECT_NAME`                                                                         |
| `templates/github/config.yml.tmpl`               | `./.github/ISSUE_TEMPLATE/config.yml`          | `--templates`        | `PROJECT_NAME`, `GITHUB_REPO_URL`                                                      |
| `templates/github/pull_request_template.md.tmpl` | `./.github/pull_request_template.md`           | `--templates`        | `PROJECT_NAME`, `TEST_CMD`, `PRIMARY_LANG`                                             |
| `templates/github/labels.md.tmpl`                | `./.github/labels.md`                          | `--templates`        | `PROJECT_NAME`                                                                         |
| `templates/github/copilot-instructions.md.tmpl`  | `./.github/copilot-instructions.md`            | `--templates`        | `PROJECT_NAME`, `PRIMARY_LANG`                                                         |
| `templates/github/workflows/pr-title.yml.tmpl`   | `./.github/workflows/pr-title.yml`             | `--templates`        | _(none — static template)_                                                             |
| `templates/git/gitmessage.tmpl`                  | `./.gitmessage`                                | `--git`              | _(none — static template)_                                                             |
| `templates/git/commitlint.config.cjs.tmpl`       | `./commitlint.config.cjs`                      | `--git` + JS/TS only | `PACKAGE_MANAGER`                                                                      |
| `templates/git/lefthook.yml.tmpl`                | `./lefthook.yml`                               | `--git`              | `PROJECT_NAME`, `TEST_CMD` + `IF_RUST`/`IF_GO`/`IF_PYTHON`/`IF_TS` language blocks     |
| `templates/git/install-lefthook.sh.tmpl`         | `./scripts/install-lefthook.sh`                | `--git`              | `PROJECT_NAME`, `PACKAGE_MANAGER`                                                      |
| `templates/git/lefthook-usage.md.tmpl`           | `./docs/lefthook-usage.md`                     | `--git`              | `PROJECT_NAME`, `PRIMARY_LANG`, `LINT_CMD`, `TEST_CMD`, `IF_TS` block                  |

---

## Placeholder Reference

Every `{{VAR}}` used across all templates:

| Placeholder       | Source                                      | Description                                             |
| ----------------- | ------------------------------------------- | ------------------------------------------------------- |
| `PROJECT_NAME`    | `profile-project.sh` or user prompt         | Repository/project name (e.g., `my-app`)                |
| `PROJECT_PURPOSE` | `profile-project.sh` or user prompt         | One-sentence description of what the project does       |
| `PRIMARY_LANG`    | `profile-project.sh` → `primary_language`   | Normalised language string (e.g., `rust`, `typescript`) |
| `TEST_CMD`        | `profile-project.sh` → `test_cmd`           | Command to run the test suite (e.g., `cargo test`)      |
| `LINT_CMD`        | `profile-project.sh` → `lint_cmd`           | Command to run linting (e.g., `cargo clippy`)           |
| `BUILD_CMD`       | `profile-project.sh` → `build_cmd`          | Command to build the project (e.g., `go build ./...`)   |
| `PACKAGE_MANAGER` | `profile-project.sh` → `package_manager`    | Package manager name (e.g., `pnpm`, `uv`, `cargo`)      |
| `GITHUB_REPO_URL` | `profile-project.sh` (git remote) or prompt | Full GitHub URL (e.g., `https://github.com/org/repo`)   |

---

## Notes

- **Default templates** (no flag required) are always rendered unless `--docs-only` skips
  MCP/agent selection. The doc trio (`CLAUDE.md`, `AGENTS.md`, cursor rule) is always
  part of the default run.
- **Existing file handling**: without `--force`, the skill diffs and prompts before
  overwriting any pre-existing target. Missing sections may be appended safely to
  existing `CLAUDE.md`.
- **JS/TS gating**: `commitlint.config.cjs` is only rendered when `PRIMARY_LANG` is
  `typescript` or `javascript` (detected from `package.json` presence). The
  `lefthook.yml` and `lefthook-usage.md` templates include a `commit-msg`
  commitlint block gated by the same `{{#IF_TS}}` conditional.
- **Lefthook scaffold**: `lefthook.yml` + `scripts/install-lefthook.sh` +
  `docs/lefthook-usage.md` are emitted together under `--git`. The install
  script is always overwritten (managed tooling); `lefthook.yml` follows the
  standard diff-and-ask rule so user edits are preserved.
- **Agent-facing PR guardrails**: `copilot-instructions.md` and
  `workflows/pr-title.yml` ship together under `--templates`. The workflow
  enforces the Conventional Commits title rules the instructions document —
  agents that open a PR with `[WIP]` / `Draft:` / `Initial plan` in the
  title get a failing required check, not a silent merge. Both files follow
  diff-and-skip update semantics.

---

See also: [`flag-reference.md`](flag-reference.md), [`project-profile-heuristics.md`](project-profile-heuristics.md).
