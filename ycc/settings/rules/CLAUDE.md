# Agent Rules (User-Global)

Generic agent-runtime guidance that applies to any project. Project-specific rules
in the current repo's `CLAUDE.md` / `AGENTS.md` override these.

This file is installed by `install.sh --settings` and symlinked into each supported
runtime's user-global config directory (Claude Code, Cursor, Codex, opencode).

## Precedence

1. System, developer, and explicit user instructions for the task.
2. The current project's `CLAUDE.md` / `AGENTS.md` as repo policy.
3. This file (user-global defaults).
4. General best practices when nothing above conflicts.

## Workflow Orchestration

### 1. Plan Mode Default

- Enter plan mode for any non-trivial task (3+ steps or architectural decisions).
- If something goes sideways, STOP and re-plan immediately — don't keep pushing.
- Use plan mode for verification steps, not just building.
- Write detailed specs upfront to reduce ambiguity.

### 2. Subagent Strategy

- Use subagents liberally to keep the main context window clean.
- Offload research, exploration, and parallel analysis to subagents.
- For complex problems, throw more compute at it via subagents.
- One task per subagent for focused execution.

### 3. Self-Improvement Loop

- After any correction from the user, update the repo's lessons file (e.g.,
  `tasks/lessons.md`) when that convention exists.
- Write rules for yourself that prevent the same mistake.
- Iterate on these lessons until mistake rate drops.
- Review lessons at session start for relevant projects.

### 4. Verification Before Done

- Never mark a task complete without proving it works.
- Diff behavior between main and your changes when relevant.
- Ask yourself: "would a staff engineer approve this?"
- Run tests, check logs, demonstrate correctness.

### 5. Demand Elegance (Balanced)

- For non-trivial changes: pause and ask "is there a more elegant way?"
- If a fix feels hacky: "knowing everything I know now, implement the elegant
  solution."
- Skip this for simple, obvious fixes — don't over-engineer.
- Challenge your own work before presenting it.

### 6. Autonomous Bug Fixing

- When given a bug report: just fix it. Don't ask for hand-holding.
- Point at logs, errors, failing tests — then resolve them.
- Zero context switching required from the user.
- Fix failing CI without being told how.

### 7. Task Management

1. **Plan first**: Use the repo's existing planning surface (e.g., `tasks/todo.md`
   where that convention exists) or an in-session task tracker.
2. **Verify plan**: Check the plan before implementation on non-trivial work.
3. **Track progress**: Mark items complete as you go.
4. **Explain changes**: Give high-level progress updates at each major step.
5. **Document results**: Add a short outcome section to the active tracker.
6. **Capture lessons**: Update the repo's lessons file after corrections.

## Core Principles

- **Simplicity first**: Make every change as simple as possible. Impact minimal code.
- **No laziness**: Find root causes. No temporary fixes. Senior-developer standards.
- **Minimal impact**: Changes should only touch what's necessary. Avoid introducing
  bugs in unrelated areas.

## Development Principles

### Type Safety

- Use strict typing where the language supports it. Never use `any`-equivalent escape
  hatches (`any`, `interface{}` as a catch-all, unchecked `unsafe`, unannotated
  dynamic values, etc.) without documented justification.
- Look up types rather than guessing.
- Prefer strict typing over loose typing.

### Error Handling

- **Throw errors early and often.** Do not use fallbacks that hide real issues.
- Fail-fast — catch issues at development time, not runtime.
- Use proper error boundaries and exception handling at system boundaries.
- Log errors with sufficient context for debugging.

### Refactoring Philosophy

- Prefer clean refactors over layering temporary compatibility shims.
- Do not use fallbacks during refactoring when they only hide the real issue.
- Preserve external contracts unless the task or repo conventions explicitly allow
  breaking changes.

## Code Quality Standards

### Functions and Methods

- Keep functions small and focused on a single responsibility.
- Use descriptive names for functions, variables, and classes.
- Prefer pure functions where possible.

### Documentation

- Write self-documenting code with clear names.
- Add doc comments for complex functions and public APIs.
- Keep inline comments minimal and focused on "why", not "what".

### Testing

- Write tests for new features and bug fixes.
- Prefer unit tests over integration tests where possible.
- Test edge cases and error conditions.

## MUST / MUST NOT

- **Secrets**: Never commit `.env`, `.env.encrypted`, tokens, or API keys.
- **Issues**: Use the YAML form templates under `.github/ISSUE_TEMPLATE/` when
  present. Do not create title-only or template-bypass issues. If
  `gh issue create --template` fails, create the issue via GitHub API/tooling with a
  body that mirrors the form fields, then apply correct labels — not a vague
  one-liner.
- **Pull requests**: Follow `.github/pull_request_template.md` when present. Always
  link the related issue (`Closes #…`). Label PRs using the project taxonomy —
  never invent ad-hoc labels.
- **Commits**: Use Conventional Commits 1.0.0 —
  `feat|fix|docs|refactor|perf|test|build|ci|chore(scope): …`. Write the title as
  you want it to appear in a changelog.
- **Internal docs commits**: Files under `docs/plans`, `docs/research`, or
  `docs/internal` must use `docs(internal): …`. Other non-user-facing churn: prefer
  `chore(…): …` to stay out of release notes.
- **Large features**: Split into smaller phases and tasks with clear dependencies
  and order of execution.
- **File size (~500 lines)**: Aim for around 500 lines per file as a soft cap.
  Files that drift meaningfully past that must be refactored into smaller modules
  unless the content is inherently contiguous (generated code, schemas, large test
  fixtures). The intent is maintainability, not a hard ceiling.
- **Modularity & reuse**: Decompose into small, cohesive units — submodules,
  libraries, or reusable components — with a clear public surface and minimal
  cross-module coupling. No copy-paste duplication (DRY): extract shared logic into
  a shared module. Prefer composition over inheritance. Avoid circular dependencies.
- **Single responsibility**: Each function, module, and component must have one
  clear reason to exist. Split when a unit grows more than one responsibility.
- **MCP**: When an MCP server fits the task (GitHub, docs, browser, etc.), prefer
  it. Read each tool's schema/descriptor before calling.

## SHOULD (implementation)

- **Naming**: Intention-revealing names for functions, types, and modules. Public
  APIs should read like documentation.
- **No dead code**: Remove unused code, imports, and commented-out blocks. Git
  preserves history.
- **Dependency hygiene**: Before adding a new dependency, check whether an existing
  one does the job. New deps need a justification (maintenance cost, license,
  security).
- **Fail fast at boundaries**: Validate inputs at module and system boundaries;
  propagate via typed errors. Never silently swallow errors.
- **Tests alongside changes**: New or modified behavior ships with tests in the same
  change.
- **Default to worktrees**: For non-trivial work (multi-step features, refactors,
  changes touching multiple files), start in a git worktree instead of the main
  checkout. See [Git Worktrees](#git-worktrees) below. Fall back to the main
  checkout only when the task is a one-liner, must observe the current working
  tree state, or worktree creation is blocked (detached HEAD, shallow clone,
  submodule issues).

## Git & Conventional Commits

Every commit title must match:

```
<type>[optional scope]: <description>
```

### Types

| Type       | Purpose                                     | Version bump |
| ---------- | ------------------------------------------- | ------------ |
| `feat`     | New user-facing feature                     | minor        |
| `fix`      | User-facing bug fix                         | patch        |
| `docs`     | Documentation only                          | —            |
| `refactor` | Code change that is neither fix nor feature | —            |
| `perf`     | Performance improvement                     | —            |
| `test`     | Adding or correcting tests                  | —            |
| `build`    | Build system or external dependency changes | —            |
| `ci`       | CI/CD configuration changes                 | —            |
| `chore`    | Other non-user-facing changes               | —            |
| `style`    | Formatting/whitespace only                  | —            |

### Scope

`feat(auth): …` — scope is the module, crate, package, or area of change. Keep it
concise.

### Breaking changes

Append `!` after the type/scope (`feat!: …`) or add a `BREAKING CHANGE: …` footer.
Either triggers a major version bump.

### Internal docs

Use `docs(internal): …` for files under `docs/plans`, `docs/research`, or
`docs/internal`. These stay out of release notes.

## Git Worktrees

**Strong preference**: work in a git worktree for any non-trivial task.
Worktrees keep the main checkout clean for parallel work, let multiple agents
run concurrently without stepping on each other, and make it trivial to abandon
a failed attempt (`git worktree remove`). Use the main checkout only when the
task is a one-liner, requires observing the current working tree state, or
worktree creation is blocked.

The Claude Code harness defaults to creating worktrees inside the current repo at
`<repo>/.claude/worktrees/`. That location pollutes the working tree, shows up in
`git status` of unrelated repos, and is easy to forget and hard to reap.

- **Preferred parent**: `~/.claude-worktrees/` for all agent-managed worktrees,
  named `<repo>-<branch>/`. Keeps them outside every repo and trivially bulk-clean.
- **Manual creation**: when invoking `git worktree add` yourself, target
  `~/.claude-worktrees/<repo>-<branch>/` — never a path inside the current repo.
- **Harness-created worktrees** (`isolation: "worktree"`, `EnterWorktree`): the
  only way to relocate these is a `WorktreeCreate` hook in
  `~/.claude/settings.json`. No environment variable or settings key controls the
  parent directory directly — the hook receives the intended path and returns a
  replacement path.
- **Repo hygiene**: if the harness has already created `<repo>/.claude/worktrees/`,
  add `.claude/worktrees/` to `.gitignore` before committing.

## GitHub Workflow

### Issue Templates

When a repository has YAML form templates under `.github/ISSUE_TEMPLATE/`, use
them. Never bypass templates with `--title`-only issue creation.

Practical CLI limitation: `gh issue create` does not reliably support combining
`--template` with `--body` / `--body-file`, and in some environments reports
"no templates found" for YAML issue forms. If that blocks you, create the issue via
GitHub API/tooling with a body that mirrors the form fields, then apply the correct
labels. Do not fall back to a vague or title-only issue.

### Pull Requests

- Follow the repo's `.github/pull_request_template.md` when present.
- Always link the related issue (`Closes #…`).
- Label PRs using the project's taxonomy.
- Small, focused PRs over large omnibus ones.

### Labels

Use only the repo's defined label taxonomy — never create ad-hoc labels. Common
colon-prefixed families (defer to the repo's actual set when it differs):

- `type:` bug, feature, docs, refactor, compatibility, build, migration
- `area:` module-specific scopes
- `priority:` critical, high, medium, low
- `status:` needs-triage, in-progress, blocked, needs-info
- Standalone: `good first issue`, `help wanted`, `duplicate`, `wontfix`

## Repository-Level Guidelines

### File Organization

- Follow existing project structure and conventions.
- Group related functionality together.
- Keep components small and composable.

### Dependencies

- Check existing dependencies before adding new ones.
- Prefer well-maintained libraries.
- Avoid unnecessary dependencies.

### Performance

- Consider performance implications of code changes.
- Use appropriate data structures and algorithms.
- Profile and optimize when necessary.

## Verification Before Done

Run the repo's test, lint, and build commands before marking any task complete.
Confirm output matches expectations — do not rely solely on "it compiled".

## Security Guidelines

- Never commit secrets, API keys, or sensitive information.
- Use environment variables for configuration.
- Validate and sanitize all user inputs.
- Follow security best practices for the technology stack.
