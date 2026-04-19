# `docs/` — Repository Documentation

Hand-maintained documentation for the `claude-plugins` repository. The
top-level `README.md` covers user-facing plugin surfaces (skills, commands,
agents); this directory holds everything else: implementation plans, release
notes, review artifacts, and ad-hoc recommendations.

The repository's authoritative agent-runtime rules live in
[`../CLAUDE.md`](../CLAUDE.md) (and its mirrored
[`../AGENTS.md`](../AGENTS.md), [`../.cursor/rules/`](../.cursor/rules/)
twins). Per-skill documentation lives inline at
`../ycc/skills/<name>/SKILL.md`.

## Layout

| Path                           | Purpose                                                                          |
| ------------------------------ | -------------------------------------------------------------------------------- |
| `plans/`                       | Multi-phase implementation plans — see below.                                    |
| `releases/`                    | One file per tagged release, drafted by `ycc:bundle-release`.                    |
| `prps/`                        | Product Requirements / Plans / Reviews — PRP-workflow artifacts.                 |
| `inventory.json`               | **Generated.** Skill/command/agent manifest. Regenerate via `./scripts/sync.sh`. |
| `pre-commit-recommendation.md` | Stand-alone note on pre-commit hook policy.                                      |

## Plans

Multi-phase implementation plans capture non-trivial changes that span
multiple commits. Scope-creep, dependency order, and risk notes belong here,
not in commit messages.

- [`plans/2026-04-07-consolidate-plugins-to-ycc.md`](plans/2026-04-07-consolidate-plugins-to-ycc.md)
  — the 2.0.0 collapse from 9 separate plugins into the unified `ycc`
  bundle.

New plans are named `YYYY-MM-DD-<kebab-case-summary>.md`. Commit them with
`docs(internal): …` so they stay out of release notes.

## Releases

One file per tagged release, drafted by the `/ycc:bundle-release` skill and
referenced by `gh release create --notes-file`. Structure is enforced by the
template in
[`../ycc/skills/bundle-release/references/release-notes-template.md`](../ycc/skills/bundle-release/references/release-notes-template.md).

Latest entries:

- [`releases/2.5.0.md`](releases/2.5.0.md) — `ycc:git-cleanup` skill,
  `--hooks` install flag, `--worktree` task isolation, skill↔command
  pairing policy.
- [`releases/2.4.0.md`](releases/2.4.0.md)
- [`releases/2.3.2.md`](releases/2.3.2.md) · [`2.3.1`](releases/2.3.1.md) · [`2.3.0`](releases/2.3.0.md)
- [`releases/2.2.0.md`](releases/2.2.0.md)
- [`releases/2.1.0.md`](releases/2.1.0.md)

## PRP artifacts

Outputs from the PRP (Product Requirements / Plan / Review) commands:

- `prps/reviews/` — review artifacts produced by `/ycc:code-review`.
- `prps/reviews/fixes/` — fix reports produced by `/ycc:review-fix`.

PRP plans and specs are written to `docs/prps/plans/` and `docs/prps/specs/`
on demand; those subdirectories appear once the corresponding command has
been run.

## Other

- [`pre-commit-recommendation.md`](pre-commit-recommendation.md) — guidance
  on the pre-commit hook policy used by this repo.

## Generated vs. source-of-truth

- `inventory.json` and the top-level `README.md` are **generated**. Edit the
  inputs (`ycc/` tree and the generator templates), then run
  `./scripts/sync.sh`.
- Everything else in this directory is hand-edited.

See [`../CONTRIBUTING.md`](../CONTRIBUTING.md) for the scope policy and
[`../CLAUDE.md`](../CLAUDE.md) for conventional commit rules — notably the
`docs(internal): …` prefix for anything under `docs/plans/`,
`docs/research/`, or `docs/internal/`.
