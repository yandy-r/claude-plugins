# YAN-702 — Consolidate planning workflow

Linear: YAN-702 · GitHub: #195 · Target: next minor release from `main` (trunk-only, no backport)

## Decision

`ycc:plan-workflow` is canonical. `shared-context` and `parallel-plan` stay as public skills and
commands, rewritten as thin forced-mode aliases that read
`${CLAUDE_PLUGIN_ROOT}/skills/plan-workflow/SKILL.md`. No public entry point is removed. No
default-off switch: entry points keep working; behavior changes are documented in the PR body.

## Lanes (non-overlapping write scopes)

| Lane | Owner  | Scope                                                                                                                           |
| ---- | ------ | ------------------------------------------------------------------------------------------------------------------------------- |
| A    | fixer  | `plan-workflow/templates/{research-agents,planning-agents,validation-agents}.md` union-merge; delete standalone template copies |
| B    | fixer  | move scripts into `plan-workflow/scripts/`; delete duplicate validators; `plan-workflow/SKILL.md` refs + 5 gap fixes            |
| C    | fixer  | rewrite `shared-context/SKILL.md`, `parallel-plan/SKILL.md`; command one-liners; README note                                    |
| D    | parent | `./scripts/sync.sh`, `./scripts/validate.sh`, evidence checks, PR                                                               |

## Mode contract (shared by lanes B and C)

- `--research-only` sets `RESEARCH_ONLY=true`; canonical stops after `shared.md` + validation.
- `--plan-only` sets `PLAN_ONLY=true`; canonical runs `plan-workflow/scripts/check-prerequisites.sh` and stops on failure.
- `--research-only` + `--plan-only` together: usage error, no writes.
- `--dry-run`: handled before any `mkdir`; writes nothing.
- `--no-checkpoint`: skip interactive checkpoint.

## Gap fixes in canonical

1. `--plan-only` without `shared.md` fails fast.
2. Mutual exclusion of mode flags.
3. Dry-run before directory creation.
4. Explicit research-only stop path and mode-aware final summary.
5. Structural plan validation runs after validation-agent fixes.

## Intentional behavior changes

- Plan validation uses `validate-workflow-plan.sh` only: missing `### Phase` is now an error.
- `--plan-only` no longer falls back to full research.
- Alias team prefixes `sc-`/`pp-` become `pw-`.

## Deferred

`plan-workflow/SKILL.md` split under ~500 lines; `--optimized` drift audit; checkpoint template trim.

## Evidence

1. `./scripts/sync.sh && ./scripts/validate.sh` green.
2. No `shared-context/(scripts|templates)` or `parallel-plan/(scripts|templates)` refs in `ycc/` or `scripts/`.
3. Template diffs vs old standalone copies: no dropped requirement lines.
4. Validator fixtures: valid plan exits 0; plan without `### Phase` exits 1.
5. Static checks for forced-mode blocks, prereq gate, mutual exclusion, dry-run order, research-only stop.
