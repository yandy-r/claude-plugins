# Plan: /goal integration for ycc:prp-implement

## Summary

Make `ycc:prp-implement` loop-to-completion friendly with Claude Code's / Codex CLI's
`/goal` directive. The work has three parts: (1) make every success signal
**transcript-observable** by printing a verbatim machine-readable block in Phase 6
OUTPUT, (2) add a `## /goal pairing` section to the skill documenting the recommended
condition template plus worktree/interactive caveats, and (3) surface the recommended
`/goal` invocation in the `/ycc:prp-implement` command help. Then regenerate and
validate the Cursor/Codex/opencode bundles.

## User Story

As a developer running a PRP implementation plan, I want to pair `/ycc:prp-implement`
with `/goal`, so that the agent continues through every phase checkpoint to completion
automatically instead of me re-prompting after each batch, validation phase, and report
write.

## Problem → Solution

Today `prp-implement` returns control at five CHECKPOINT boundaries and (in parallel
mode) at interactive batch prompts, so the user re-prompts repeatedly. `/goal` can drive
the session to a verifiable end state — **but its evaluator only judges what Claude has
surfaced in the transcript; it does not read files or run tools**. The skill's seven
success signals (`TASKS_COMPLETE` … `PLAN_ARCHIVED`) currently live only as a static
documentation checklist and are never printed, and the Phase-4 "Validation Results"
table exists only inside the written report file. → Print a verbatim signal block in
Phase 6, document a transcript-keyed `/goal` condition, and surface it in the command
help.

## Metadata

- **Complexity**: Small–Medium
- **Source PRD**: N/A (GitHub issue #92)
- **PRD Phase**: N/A
- **Estimated Files**: 2 source files edited + generated bundles (Cursor/Codex/opencode) regenerated
- **GitHub Issue**: <https://github.com/yandy-r/claude-plugins/issues/92> (labels: type:feature, area:cli, priority:medium, status:needs-triage)

---

## Batches

Tasks grouped by dependency for parallel execution. Tasks within the same batch run concurrently; batches run in order.

| Batch | Tasks    | Depends On | Parallel Width |
| ----- | -------- | ---------- | -------------- |
| B1    | 1.1, 1.2 | —          | 2              |
| B2    | 2.1      | B1         | 1              |
| B3    | 3.1      | B2         | 1              |

- **Total tasks**: 4
- **Total batches**: 3
- **Max parallel width**: 2

> Note: 1.1 edits `ycc/skills/prp-implement/SKILL.md`; 1.2 edits `ycc/commands/prp-implement.md`. Different files → safe to run concurrently in B1.

---

## UX Design

### Before

```text
$ /ycc:prp-implement docs/prps/plans/foo.plan.md
... Phase 1 ... CHECKPOINT  ← control returns to user, user re-prompts
... Phase 4 ... CHECKPOINT  ← control returns, user re-prompts
... Phase 5 ... CHECKPOINT  ← control returns, user re-prompts
## Implementation Complete    (no machine-readable completion token)
```

### After

```text
$ /goal Implement docs/prps/plans/foo.plan.md via ycc:prp-implement;
        done when transcript shows all 7 signals PASS; stop after 25 turns.
◎ /goal active
... runs through every CHECKPOINT without returning control ...
## Implementation Complete
TASKS_COMPLETE: PASS
TYPES_PASS: PASS
LINT_PASS: PASS
TESTS_PASS: PASS
BUILD_PASS: PASS
REPORT_CREATED: PASS
PLAN_ARCHIVED: PASS          ← evaluator reads these 7 lines → goal met, loop clears
```

### Interaction Changes

| Touchpoint               | Before                                              | After                                                      | Notes                                                       |
| ------------------------ | --------------------------------------------------- | ---------------------------------------------------------- | ----------------------------------------------------------- |
| Phase 6 OUTPUT           | Prose `## Implementation Complete` + `[done]` table | Same, plus a verbatim 7-line signal block printed below it | New machine-readable block; existing human output unchanged |
| Per-CHECKPOINT prompting | User re-invokes after each                          | `/goal` auto-continues across CHECKPOINTs                  | Behavioral change is driven by `/goal`, not the skill       |
| Batch failure (parallel) | Interactive `AskUserQuestion`                       | Still interactive — `/goal` cannot answer it               | Documented caveat: the loop stalls awaiting human input     |

---

## Mandatory Reading

Files that MUST be read before implementing:

| Priority       | File                                                        | Lines      | Why                                                                 |
| -------------- | ----------------------------------------------------------- | ---------- | ------------------------------------------------------------------- |
| P0 (critical)  | `ycc/skills/prp-implement/SKILL.md`                         | 660-781    | Phase 6 OUTPUT block + Success Criteria + Next Steps — edit targets |
| P0 (critical)  | `ycc/commands/prp-implement.md`                             | 1-92       | Command frontmatter + Usage/Examples/Next-step block — edit target  |
| P1 (important) | `ycc/skills/prp-implement/SKILL.md`                         | 555-657    | Phase 4 CHECKPOINT, report write, worktree archive — caveat sources |
| P1 (important) | `ycc/skills/_shared/references/target-capability-matrix.md` | 27-51      | COMMANDS capability rows (cursor partial, codex unsupported)        |
| P2 (reference) | `ycc/skills/bundle-release/references/version-policy.md`    | 9-78       | Why NO version bump happens in this change                          |
| P2 (reference) | `scripts/sync.sh`                                           | 15, 55-103 | Regenerate entrypoint + `--only` targets                            |
| P2 (reference) | `scripts/validate.sh`                                       | 18, 85-119 | Validate entrypoint + byte-compare drift check                      |

## External Documentation

| Topic                  | Source                                                       | Key Takeaway                                                                                                                                                                                   |
| ---------------------- | ------------------------------------------------------------ | ---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| Claude Code `/goal`    | <https://code.claude.com/docs/en/goal>                       | Evaluator judges **transcript only** (no file reads, no tool calls); 4,000-char condition limit; "or stop after N turns" clause bounds the loop; requires v2.1.139+ and accepted trust dialog. |
| Codex CLI `/goal`      | <https://developers.openai.com/codex/use-cases/follow-goals> | Codex CLI (v0.128.0+) ships an equivalent `/goal`; the pairing should not assume Claude-only.                                                                                                  |
| Auto mode (complement) | <https://code.claude.com/docs/en/auto-mode-config>           | `/goal` removes per-turn prompts; auto mode removes per-tool prompts. Pair both for unattended runs.                                                                                           |

---

## Patterns to Mirror

Code/doc patterns discovered in the codebase. Follow these exactly.

### TOPICAL_SECTION_HEADING

Non-phase sections use plain Title Case `##` headings (no `## Phase N — NAME` em-dash
form). Place `## /goal pairing` alongside these trailing topical sections.

```text
// SOURCE: ycc/skills/prp-implement/SKILL.md:714,753,765,774
## Handling Failures
## Success Criteria
## Next Steps
## Agent Team Lifecycle Reference
```

### PRINTED_OUTPUT_BLOCK

Transcript-printed output is wrapped in a fenced block under a "Report to user:"
directive. The new verbatim signal lines go INSIDE this existing Phase 6 fence so they
reach the transcript.

```text
// SOURCE: ycc/skills/prp-implement/SKILL.md:662-665
Report to user:

```

## Implementation Complete

````

### NEXT_STEP_CALLOUT (command help)

Sibling PRP commands surface follow-on invocations in a `Next step …:` block at the end
of a fenced Usage/Examples block. Mirror this to add the `/goal` invocation.

```text
// SOURCE: ycc/commands/prp-implement.md:89-91
Next step after implementation completes:
  /ycc:prp-pr            # Create a pull request
  /ycc:code-review       # Review changes locally first
````

### CROSS_TARGET_CAVEAT_PHRASE

Generators reword "Claude Code" per target (Codex→"Codex", opencode→"opencode"), but the
literal advisory phrase `Claude Code only` is preserved/converted by an explicit
carve-out. The literal token `/goal` (NOT namespaced like `/ycc:goal`) passes through all
three generators untouched.

```text
// SOURCE: scripts/generate_opencode_common.py:408-409,485 ; generate_codex_common.py:36-41,167-178
opencode sentinel restores "Claude Code only"; Codex maps it to "Codex runtime only…"
/ycc:<name> → /<name> rewrite ; literal /goal is left as-is
```

### NO_SKILL_HEADING_VALIDATOR

No validator inspects SKILL.md body headings, so adding `## /goal pairing` is
structurally safe. The only failure surface is the generated-bundle content-policy regex,
which forbids un-rewritten `ycc:` / `CLAUDE_PLUGIN_ROOT` / team-tool / `subagent_type:`
tokens — none of which the new section needs.

```text
// SOURCE: scripts/validate-codex-skills.sh:104-106 ; validate-opencode-skills.sh:102-104
forbidden pattern: '/ycc:', '\bycc:', 'CLAUDE_PLUGIN_ROOT', team tools, 'subagent_type:'
```

---

## Files to Change

| File                                              | Action      | Justification                                                                                             |
| ------------------------------------------------- | ----------- | --------------------------------------------------------------------------------------------------------- |
| `ycc/skills/prp-implement/SKILL.md`               | UPDATE      | Print verbatim signal block in Phase 6 OUTPUT; add `## /goal pairing` section; cross-ref Success Criteria |
| `ycc/commands/prp-implement.md`                   | UPDATE      | Surface the recommended `/goal` invocation in the Usage/Examples + Next-step block                        |
| `.cursor-plugin/skills/prp-implement/SKILL.md`    | REGENERATED | Output of `./scripts/sync.sh` — do NOT hand-edit                                                          |
| `.codex-plugin/ycc/skills/prp-implement/SKILL.md` | REGENERATED | Output of `./scripts/sync.sh` — do NOT hand-edit                                                          |
| `.opencode-plugin/skills/prp-implement/SKILL.md`  | REGENERATED | Output of `./scripts/sync.sh` — do NOT hand-edit                                                          |
| `.opencode-plugin/commands/prp-implement.md`      | REGENERATED | Output of `./scripts/sync.sh` — opencode is the ONLY target that generates commands                       |

## NOT Building

- **No version bump.** `ycc/.claude-plugin/plugin.json` / `marketplace.json` stay at `3.1.2`. Versioning is a separate `/ycc:bundle-release` step (see `version-policy.md:9-15` — bumps are manual, not triggered by `sync.sh`).
- **No internal "loop until done" inside the skill.** Issue #92 explicitly rejected this — `/goal` composes the loop externally and works for both Claude Code and Codex CLI.
- **No printed Phase-4 "Validation Results" table.** The seven Phase-6 signals are sufficient and observable; replicating a Phase-4 table to the transcript is unnecessary scope. (The issue's draft condition referenced this table, but it is file-only and the evaluator cannot read files — see Risks.)
- **No new `target-capability-matrix.md` `/goal` row.** Optional follow-up; not required to satisfy the three issue deliverables.
- **No hooks/settings changes.** `/goal` is a user-invoked session directive; nothing in the repo's hook config needs to change.
- **No changes to argument-hint frontmatter** (kept lean; the `/goal` invocation lives in the command's help body, not the hint).

---

## Step-by-Step Tasks

### Task 1.1: Make prp-implement signals transcript-observable + document the /goal pairing — Depends on [none]

- **BATCH**: B1
- **ACTION**: Edit `ycc/skills/prp-implement/SKILL.md` to (a) print a verbatim machine-readable signal block in Phase 6 OUTPUT, (b) add a `## /goal pairing` section, and (c) cross-reference it from `## Success Criteria`.
- **IMPLEMENT**:
  1. In the Phase 6 OUTPUT fenced block (currently ending at the `> Next step:` line, `:709`), append — INSIDE the same ` ``` ` fence so it prints to the transcript — a verbatim signal block. Each line maps to one of the existing seven Success Criteria keys, printed as `KEY: PASS` (or `KEY: FAIL` if that criterion is unmet):

     ```
     ### Goal Signals (machine-readable — printed verbatim for /goal)

     TASKS_COMPLETE: PASS
     TYPES_PASS: PASS
     LINT_PASS: PASS
     TESTS_PASS: PASS
     BUILD_PASS: PASS
     REPORT_CREATED: PASS
     PLAN_ARCHIVED: PASS
     ```

     Add a one-line instruction above the block: "Print every signal verbatim. Use `PASS` only when the criterion in `## Success Criteria` is met; otherwise `FAIL`."

  2. Add a new topical section `## /goal pairing` near `## Success Criteria` / `## Next Steps` (plain Title-Case heading, NOT `## Phase N —` form). Content: a 1-2 sentence intro, the recommended condition template (see IMPLEMENT step in Task notes / the "Recommended /goal condition" in Notes), and the three caveats (worktree cwd, interactive batch prompts, auto-mode complement). Use the literal token `/goal` (never `/ycc:goal`).
  3. In `## Success Criteria` (`:753-761`), add a trailing note: "These keys are emitted verbatim in the Phase 6 OUTPUT 'Goal Signals' block so a `/goal` evaluator can observe completion from the transcript." (DRY — do not duplicate the key list.)

- **MIRROR**: PRINTED_OUTPUT_BLOCK (signal lines go inside the existing Phase 6 fence); TOPICAL_SECTION_HEADING (`## /goal pairing` matches sibling topical sections); CROSS_TARGET_CAVEAT_PHRASE (use exact phrase `Claude Code only` is NOT accurate here — `/goal` is Claude **and** Codex; phrase the caveat as "Claude Code and Codex CLI only" and accept per-target rewording, see GOTCHA).
- **GOTCHA**:
  - The signal block MUST be inside the `Report to user:` fenced block, or it won't reach the transcript and `/goal` won't see it.
  - Do NOT reference file paths (e.g. the report file) as the completion proof — the `/goal` evaluator cannot read files; it only judges transcript text.
  - The opencode/Codex generators reword "Claude Code". A sentence like "Claude Code's `/goal` command" becomes "opencode's `/goal` command" in the opencode bundle (misleading — opencode has no `/goal`). Phrase the section so the rewrite stays sensible (e.g. "the `/goal` directive available in Claude Code and Codex CLI") and rely on Task 3.1 to eyeball the result.
  - Do not embed `/ycc:` (gets rewritten — fine) or `subagent_type:` / team-tool tokens (would trip the content-policy validator).
- **VALIDATE**:
  - `grep -n 'TASKS_COMPLETE: PASS' ycc/skills/prp-implement/SKILL.md` returns a hit INSIDE the Phase 6 fenced block.
  - `grep -n '^## /goal pairing' ycc/skills/prp-implement/SKILL.md` returns exactly one hit.
  - `grep -n 'subagent_type:\|CLAUDE_PLUGIN_ROOT' ycc/skills/prp-implement/SKILL.md` shows no NEW occurrences in the added section.

### Task 1.2: Surface the recommended /goal invocation in the command help — Depends on [none]

- **BATCH**: B1
- **ACTION**: Edit `ycc/commands/prp-implement.md` to add the recommended `/goal` pairing to the help body.
- **IMPLEMENT**: In the fenced Usage/Examples block (`:67-92`), add an example showing the `/goal` pairing, and extend the `Next step after implementation completes:` block (`:89-91`) — or add a short `Tip:` line — pointing to the `## /goal pairing` section of the skill. Keep the recommended condition concise (the full template lives in the skill). Example to add under `Examples:`:

  ```text
  /goal Implement docs/prps/plans/<name>.plan.md via the ycc:prp-implement workflow;
        done when the transcript shows all 7 Goal Signals PASS; stop after 25 turns.
    # loop to completion across every CHECKPOINT without re-prompting (Claude Code / Codex CLI)
  ```

- **MIRROR**: NEXT_STEP_CALLOUT — match the 2-space-indented `command  # inline comment` style already used in this file's Examples/Next-step blocks.
- **IMPORTS**: None.
- **GOTCHA**: Do NOT touch the `argument-hint` frontmatter (`:3`) — keep it lean (decision recorded in NOT Building). The command file delegates to the skill, so do not restate the full caveats here; link to the skill's `## /goal pairing` section instead.
- **VALIDATE**: `grep -n '/goal' ycc/commands/prp-implement.md` returns the new example line(s); `python3 -c "import re,sys"` not needed — frontmatter untouched.

### Task 2.1: Regenerate and validate all compatibility bundles — Depends on [1.1, 1.2]

- **BATCH**: B2
- **ACTION**: Regenerate the Cursor/Codex/opencode bundles from the edited source, then run the full validator suite.
- **IMPLEMENT**: Run from the repo root:

  ```bash
  ./scripts/sync.sh
  ./scripts/validate.sh
  ```

  (Optionally scope with `--only cursor,codex,opencode` / `--only json` for faster iteration, but run the full pair before completion.)

- **MIRROR**: NO_SKILL_HEADING_VALIDATOR — expect no structural heading failures; the only realistic failure is content-policy drift or byte-compare drift if `sync.sh` was not run.
- **GOTCHA**:
  - `sync.sh` targets are `inventory cursor codex opencode` (no `json`); `validate.sh` adds `json`. Run BOTH scripts, not just one.
  - `validate.sh` byte-compares the committed bundle against a fresh re-generation — if you edited source but forgot `sync.sh`, validation fails with a drift error. Always sync before validate.
  - The command edit (Task 1.2) only propagates to `.opencode-plugin/commands/prp-implement.md` (Cursor/Codex have no command generator) — this is expected, not a gap.
- **VALIDATE**:
  - `./scripts/validate.sh` exits 0.
  - `grep -rn 'TASKS_COMPLETE: PASS' .cursor-plugin/skills/prp-implement/SKILL.md .codex-plugin/ycc/skills/prp-implement/SKILL.md .opencode-plugin/skills/prp-implement/SKILL.md` returns a hit in all three generated copies.

### Task 3.1: Cross-target prose verification of the generated /goal section — Depends on [2.1]

- **BATCH**: B3
- **ACTION**: Manually inspect the generated Codex and opencode SKILL.md copies to confirm the `## /goal pairing` section reads sensibly after the per-target "Claude Code" rewrites.
- **IMPLEMENT**: Open `.codex-plugin/ycc/skills/prp-implement/SKILL.md` and `.opencode-plugin/skills/prp-implement/SKILL.md`, locate the `## /goal pairing` section, and verify the reworded text is not misleading (e.g. opencode must not claim it ships `/goal`). If misleading, revise the SOURCE wording in Task 1.1 (re-run from B1), not the generated files.
- **MIRROR**: CROSS_TARGET_CAVEAT_PHRASE — confirm the literal `/goal` survived untouched and that platform claims remain accurate post-rewrite.
- **GOTCHA**: `validate.sh` confirms byte-parity but NOT prose quality — this human/agent eyeball is the only check for misleading reworded sentences. Never hand-edit generated bundles; fix the source and re-sync.
- **VALIDATE**:
  - The opencode-generated section makes no false claim that opencode provides `/goal`.
  - The Codex-generated section reads correctly (e.g. "Codex CLI" references survive or are reworded sensibly).
  - Re-run `./scripts/validate.sh` if any source fix was needed; exits 0.

---

## Testing Strategy

This repo has no unit-test harness for skill prose; verification is the generate-and-validate
pipeline plus targeted greps (see CLAUDE.md → "Testing Changes").

### Validation Checks

| Check                           | Command                                                                         | Expected Output | Edge Case?      |
| ------------------------------- | ------------------------------------------------------------------------------- | --------------- | --------------- |
| Signal block present in source  | `grep -c 'TASKS_COMPLETE: PASS' ycc/skills/prp-implement/SKILL.md`              | `1`             | —               |
| `/goal pairing` section present | `grep -c '^## /goal pairing' ycc/skills/prp-implement/SKILL.md`                 | `1`             | —               |
| No forbidden tokens added       | `grep -n 'subagent_type:' ycc/skills/prp-implement/SKILL.md` (new section)      | no new hits     | content-policy  |
| Command help mentions /goal     | `grep -c '/goal' ycc/commands/prp-implement.md`                                 | `>= 1`          | —               |
| Bundles regenerated (no drift)  | `./scripts/validate.sh`                                                         | exit 0          | drift detection |
| Signal block in all 3 bundles   | `grep -rl 'TASKS_COMPLETE: PASS' .cursor-plugin .codex-plugin .opencode-plugin` | 3 paths         | cross-target    |

### Edge Cases Checklist

- [ ] Source edited but `sync.sh` not run → `validate.sh` must FAIL with a drift error (proves the guard works).
- [ ] opencode-generated section does not falsely claim opencode ships `/goal` (prose rewrite edge case).
- [ ] `/goal` literal token survives all three generators un-rewritten (not turned into `/<name>`).
- [ ] JSON manifests still valid and version unchanged at `3.1.2`.

---

## Validation Commands

### Static Analysis

```bash
# Shell + Python lint (only if scripts were touched — they are not, but safe to run)
npm run lint:modified
```

EXPECT: Zero lint errors (or "no modified lintable files").

### Bundle Regeneration + Validation (primary gate)

```bash
./scripts/sync.sh
./scripts/validate.sh
```

EXPECT: `sync.sh` regenerates Cursor/Codex/opencode; `validate.sh` exits 0 (no drift, no content-policy violations, JSON valid).

### JSON Validation

```bash
python3 -m json.tool .claude-plugin/marketplace.json > /dev/null
python3 -m json.tool ycc/.claude-plugin/plugin.json > /dev/null
```

EXPECT: Both parse; version remains `3.1.2` in both.

### Targeted Greps

```bash
grep -n 'TASKS_COMPLETE: PASS' ycc/skills/prp-implement/SKILL.md
grep -n '^## /goal pairing' ycc/skills/prp-implement/SKILL.md
grep -rl 'TASKS_COMPLETE: PASS' .cursor-plugin .codex-plugin .opencode-plugin
```

EXPECT: signal block + section present in source; signal block present in all three generated bundles.

### Manual Validation

- [ ] Read the rendered `## /goal pairing` section — condition template is under 4,000 chars and references only transcript-printed strings.
- [ ] Confirm the Phase 6 signal block sits INSIDE the `Report to user:` fence.
- [ ] Confirm command help example matches the file's existing indentation/comment style.

---

## Acceptance Criteria

- [ ] Phase 6 OUTPUT prints all seven signals verbatim (`TASKS_COMPLETE: PASS` … `PLAN_ARCHIVED: PASS`) inside the transcript-visible fence.
- [ ] `## /goal pairing` section added with a recommended, transcript-keyed condition template + worktree/interactive/auto-mode caveats.
- [ ] `## Success Criteria` cross-references the Phase 6 signal block (no key-list duplication).
- [ ] `/ycc:prp-implement` command help surfaces the recommended `/goal` invocation.
- [ ] `./scripts/validate.sh` passes (bundles regenerated, no drift, JSON valid).
- [ ] Generated opencode/Codex sections read sensibly after per-target rewrites.
- [ ] Version unchanged (`3.1.2`); no internal loop baked into the skill.

## Completion Checklist

- [ ] Edits follow discovered patterns (topical heading, printed-fence, next-step callout).
- [ ] Condition template references transcript output only — never file paths.
- [ ] No forbidden tokens (`subagent_type:`, raw team tools) added to the skill body.
- [ ] Cursor/Codex/opencode bundles regenerated via `sync.sh` (not hand-edited).
- [ ] `validate.sh` green; JSON manifests valid.
- [ ] No version bump (left for `/ycc:bundle-release`).
- [ ] No unnecessary scope additions (no Phase-4 printed table, no capability-matrix row).

## Risks

| Risk                                                                                                                    | Likelihood        | Impact                                      | Mitigation                                                                                                           |
| ----------------------------------------------------------------------------------------------------------------------- | ----------------- | ------------------------------------------- | -------------------------------------------------------------------------------------------------------------------- |
| Issue's draft condition references the report **file** and a Phase-4 table — both unobservable to the `/goal` evaluator | High (as drafted) | High (goal would never fire / fire wrongly) | Plan corrects the condition to key off the seven verbatim transcript signals only; documented in Notes               |
| "Claude Code" → target rewrite makes the opencode/Codex section claim a `/goal` that doesn't exist there                | Medium            | Medium (misleading docs)                    | Phrase the section as "Claude Code and Codex CLI"; Task 3.1 eyeballs generated output; fix source + re-sync if wrong |
| Editing source without running `sync.sh` ships drifted bundles                                                          | Medium            | High (CI/validate failure)                  | Task 2.1 runs `sync.sh` then `validate.sh`; drift check catches it                                                   |
| Signal block placed outside the printed fence → `/goal` can't observe it                                                | Low               | High (feature silently broken)              | Task 1.1 GOTCHA + Manual Validation explicitly check fence placement                                                 |
| Interactive batch-failure prompts stall a `/goal` loop (evaluator can't answer `AskUserQuestion`)                       | Medium            | Low (documented limitation)                 | Section caveat tells users to pair with auto mode and expect manual intervention on batch failures                   |

## Notes

### Recommended /goal condition (transcript-keyed — for the `## /goal pairing` section)

```text
/goal Implement the plan at docs/prps/plans/<name>.plan.md using the ycc:prp-implement
workflow, continuing through every phase CHECKPOINT without returning control to me.
Done when the transcript shows the Phase 6 "## Implementation Complete" output followed
by all seven Goal Signals printed verbatim — TASKS_COMPLETE: PASS, TYPES_PASS: PASS,
LINT_PASS: PASS, TESTS_PASS: PASS, BUILD_PASS: PASS, REPORT_CREATED: PASS,
PLAN_ARCHIVED: PASS. If any signal prints FAIL, keep fixing and re-running validation
until all seven are PASS. Stop after 25 turns if not achieved.
```

- Well under the 4,000-char limit. Keys off transcript text only (no file reads).
- The `Stop after 25 turns` clause bounds runaway loops (per the `/goal` doc's "or stop after N turns" guidance).

### Caveats to document in the section

1. **Worktree cwd**: when `prp-implement` runs in worktree mode (the default), the report and archived plan are written under `~/.claude-worktrees/<repo>-<slug>/docs/prps/...`, not the main checkout. This does NOT affect the `/goal` condition (which keys off printed transcript text, not file paths) — but tell users not to write conditions that point at a main-repo file path.
2. **Interactive failure prompts**: parallel/team batch failures raise an `AskUserQuestion` (SKILL.md `:309`, `:434`) that `/goal` cannot answer; the loop stalls awaiting human input. Pair with **auto mode** to remove per-tool prompts, but expect to step in on batch failures.
3. **Platform**: `/goal` exists in Claude Code (v2.1.139+) and Codex CLI (v0.128.0+) only; it is not a Cursor/opencode feature. Trust dialog must be accepted and hooks not disabled.

### Why the issue's "confirm signals are printed" item is real work

Research confirmed the seven keys at `SKILL.md:753-761` are a static documentation
checklist, never echoed. The only transcript-printed table (Phase 6 "Validation Summary",
`:672-681`) uses different labels (`Type Check/Lint/Tests/Build/Integration`, `[done]`)
and does not contain the keyword tokens. Hence Item #1 requires the Phase 6 print
addition in Task 1.1 — it is not a no-op confirmation.

### Version / release

This is a documentation/prose skill change → PATCH per `version-policy.md:70-74`, but the
bump is intentionally NOT part of this change. `sync.sh` does not bump versions; the
release is cut separately via `/ycc:bundle-release`.
