# YAN-704: language skill disclosure research/design/plan

Status: bounded research and approved-scope design; implementation and validation owned by parent session.
Target: v5.2.x; branch from `main`, PR to `main`; no backport. Current baseline version: v5.1.1.
Baseline: `83efb1e4d0afd33ed003a774d90d721cc1831874` (includes YAN-712 / #194).
Measurements below read baseline objects with `git show`, not concurrently edited working files.
Research write scope: this document only. No skills, generated files, code, tracker, or commits changed by researcher.

## Actual overlap measurement

Two exact-match metrics, plus separately documented topical overlap:

- **P (prose):** distinct normalized physical lines outside YAML frontmatter and fenced code; exclude headings and Markdown table rows; require at least three ASCII alphabetic words. Strip one leading quote/list/number marker, remove backticks/asterisks/underscores, lowercase, collapse whitespace, strip terminal `. ! ; :` punctuation.
- **C (code/examples):** distinct whitespace-normalized physical lines inside fenced blocks; retain case and punctuation; require >=20 characters and one ASCII alphabetic run of >=3 characters. Includes commands and example directory trees, not only executable code.
- **L:** intersection with all five `.md` rules in matching language directory. **Common:** intersection with `coding-style`, `patterns`, `testing`, `security`, `performance`, `development-workflow`, and `code-review` common rules.
- Counts are unique eligible lines per skill. Not deletion estimates, token counts, or semantic similarity percentages. Physical-line wrapping, comments, and paraphrases affect exact matches.

| Baseline skill          |     Lines | Bytes (UTF-8) | P eligible | P L / Common | C eligible | C L / Common |
| ----------------------- | --------: | ------------: | ---------: | -----------: | ---------: | -----------: |
| go-patterns             |       673 |        14,842 |          9 |        0 / 0 |        190 |        4 / 0 |
| go-testing              |       721 |        16,996 |         21 |        0 / 0 |        225 |        1 / 0 |
| python-patterns         |       769 |        18,611 |          9 |        0 / 0 |        244 |        3 / 0 |
| python-testing          |       824 |        19,856 |         22 |        0 / 0 |        301 |        1 / 0 |
| rust-patterns           |       498 |        14,137 |          8 |        0 / 0 |        186 |       23 / 0 |
| rust-testing            |       501 |        12,008 |         26 |        0 / 0 |        149 |       27 / 0 |
| ts-patterns             |       816 |        25,195 |         43 |        0 / 0 |        328 |        0 / 0 |
| ts-testing              |       762 |        20,537 |         66 |        0 / 0 |        250 |        0 / 0 |
| Sum of per-skill counts | **5,564** |   **142,182** |    **204** |    **0 / 0** |  **1,873** |   **59 / 0** |

Zero exact prose matches does **not** mean zero policy duplication. Rules summarize/rephrase skills; most skill volume consists of examples. Code matches concentrate in Rust, including enum state handling, Cow, rstest, async tests, mockall, and test/coverage commands. Some matches are ordinary syntax; neither all 59 lines nor all topical overlap is independently removable.

### Reproduce exact counts (read-only, stdlib)

Run from repo/worktree root; baseline commit must exist. Output tuples are `(eligible, language intersection, common intersection)` for P then C.

````bash
python3 - <<'PY'
import re
import subprocess
B = "83efb1e4d0afd33ed003a774d90d721cc1831874"
def read(path):
    return subprocess.check_output(["git", "show", f"{B}:{path}"], text=True)
def eligible(text):
    result = [set(), set()]
    frontmatter = fence = False
    for index, line in enumerate(text.splitlines()):
        if index == 0 and line == "---":
            frontmatter = True
            continue
        if frontmatter:
            if line == "---":
                frontmatter = False
            continue
        if re.match(r"^\s*(```|~~~)", line):
            fence = not fence
            continue
        if not line.strip():
            continue
        if fence:
            normalized = re.sub(r"\s+", " ", line.strip())
            if len(normalized) >= 20 and re.search(r"[A-Za-z]{3}", normalized):
                result[1].add(normalized)
            continue
        if re.match(r"^\s*(#|\|)", line):
            continue
        normalized = re.sub(r"^\s*(?:>\s*)?(?:[-*+]\s+|\d+[.)]\s+)?", "", line).strip()
        if len(re.findall(r"[A-Za-z]+", normalized)) < 3:
            continue
        normalized = re.sub(r"[`*_]", "", normalized).lower()
        result[0].add(re.sub(r"\s+", " ", normalized).strip().rstrip(".!;:"))
    return result
common = [set(), set()]
for name in ["coding-style", "patterns", "testing", "security", "performance", "development-workflow", "code-review"]:
    for index, values in enumerate(eligible(read(f"ycc/rules/common/{name}.md"))):
        common[index] |= values
for lang, directory in [("go", "golang"), ("python", "python"), ("rust", "rust"), ("ts", "typescript")]:
    rules = [set(), set()]
    paths = subprocess.check_output(["git", "ls-tree", "-r", "--name-only", B, f"ycc/rules/{directory}"], text=True).splitlines()
    for path in paths:
        if path.endswith(".md"):
            for index, values in enumerate(eligible(read(path))):
                rules[index] |= values
    for kind in ["patterns", "testing"]:
        name = f"{lang}-{kind}"
        skill = eligible(read(f"ycc/skills/{name}/SKILL.md"))
        print(name, [(len(values), len(values & rules[i]), len(values & common[i])) for i, values in enumerate(skill)])
PY
````

### Shared topics versus useful skill-only detail

This is a verified topic crosswalk, not automated similarity or percentage scoring. Rule paths below are relative to `ycc/rules/`; skill section names identify baseline evidence.

| Skill           | Topical overlap and rule evidence                                                                                                                                               | Useful detail not replaced by condensed rules                                                                                                     |
| --------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------- |
| go-patterns     | `golang/coding-style.md`: formatting, small interfaces, contextual errors; `patterns.md`: functional options, consumer interfaces, DI; `security.md`: context/timeouts          | Zero values; errors.Is/As; workers, graceful shutdown, errgroup and leaks; package design, memory/performance examples                            |
| go-testing      | `golang/testing.md`: stdlib/table-driven tests, race detection, coverage                                                                                                        | Subtests, Helper/Cleanup/TempDir, golden files, interface mocks, benchmarks, fuzzing, httptest, CI                                                |
| python-patterns | `python/coding-style.md`: type hints, immutable dataclasses/NamedTuple, formatters; `patterns.md`: Protocol, DTOs, context managers/generators                                  | EAFP; chaining/custom exceptions; decorators, workload/concurrency selection, package layout, optimization and configs                            |
| python-testing  | `python/testing.md`: pytest, coverage, marker-based categorization                                                                                                              | Fixture scopes/teardown/composition, parametrization, autospec, async fixtures, temporary/env/output isolation, API/DB examples                   |
| rust-patterns   | `rust/coding-style.md`: borrowing/Cow, errors, iterators, domains/visibility; `patterns.md`: newtypes, enum state machines, builders; `security.md`: documented/minimal unsafe  | Option combinators, generic/dynamic dispatch, channels/Tokio and richer examples; overlap strongest here                                          |
| rust-testing    | `rust/testing.md`: unit/integration layout, rstest, async, mockall, names, coverage/commands                                                                                    | Result/panic distinctions, property strategies, helpers, doctests, Criterion, CI                                                                  |
| ts-patterns     | `typescript/coding-style.md`: public types, unknown narrowing, immutability; `hooks.md`: formatting/type checks; `common/coding-style.md`: typed boundaries and readable design | Discriminated unions/exhaustiveness, inference, satisfies, brands, conditional/mapped types, exports, cancellation/streaming, runtimes, toolchain |
| ts-testing      | `common/testing.md`: RED/GREEN/REFACTOR, 80% minimum, unit/integration/E2E and names; `typescript/testing.md`: Playwright E2E is complementary, not Vitest replacement          | Vitest assertions/mocks, fake timers, property tests, type-level tests, coverage config and benchmarks                                            |

Common policy overlap also includes small/cohesive modules, explicit errors and input validation (`common/coding-style.md`), testing expectations (`common/code-review.md`, `development-workflow.md`), and DI/repository concepts (`common/patterns.md`). `common/performance.md` concerns agent/model/context usage, not skill language-level optimization recipes. No assumption that all rules are installed/loaded on every target.

## Decision and alternatives

Chosen: progressive disclosure with inline actionable rules; preserve all eight names, descriptions, full frontmatter, commands, original sections and content.

- **True language-pair merge:** loses distinct public intents or needs alias wrappers; pair overlap mostly tooling/boilerplate, not equivalent workflows. Public removal/rename requires explicit approval; none granted.
- **Reference-only pointers to rules:** loses testing contracts and unique examples; assumes applicable rules loaded. Rejected.
- **Default-exposure removal:** changes discoverability, needs approval and cross-target semantics; no uniform exposure flag survives current restricted Codex/opencode frontmatter emission. Rejected for this scope.
- **Lossless disclosure:** separates frequently useful rules from long examples without new entrypoints or generator work. Rules remain concise standards; skills remain actionable depth.

## Nonvisual workflow and exact source scope

Each primer: unchanged frontmatter/title/intro; Critical Rules near top; References with plain skill-relative links and explicit `Read when:` conditions; retained original sections. Max **250 lines** including frontmatter; **no lower bound, padding, or 150-line target**. Loading behavior differs by runtime, so link alone is not an instruction. Say paths resolve from skill directory; read matching reference only when detail needed; never claim unread/missing reference loaded.

Inline: existing actionable guidance, testing lifecycle, error/isolation/cleanup requirements, commands and coverage contracts. Summary bullets must not promote optional example libraries/configurations into new mandates. Preserve 80%+ general / 90%+ public API / 100% critical targets and generated exclusions; TS 75% branch example remains unchanged, not silently standardized. Rust unsafe invariants and TS runtime/type/E2E boundaries remain near top.

Modify only eight `ycc/skills/{go,python,rust,ts}-{patterns,testing}/SKILL.md`; create two references per directory below. Ranges are baseline line numbers and complete sections, outside fences. Kept ranges remain unchanged; references may add one heading before original sections.

| Skill           | Original kept ranges   | Reference filename and moved ranges                                                                 |
| --------------- | ---------------------- | --------------------------------------------------------------------------------------------------- |
| go-patterns     | 1–16, 624–673          | `references/errors-and-concurrency.md`: 17–296; `references/design-and-tooling.md`: 297–623         |
| go-testing      | 1–17, 521–559, 643–699 | `references/test-structure.md`: 18–286; `references/advanced-testing.md`: 287–520, 560–642, 700–721 |
| python-patterns | 1–16, 704–769          | `references/core-idioms.md`: 17–311; `references/design-and-tooling.md`: 312–703                    |
| python-testing  | 1–16, 748–824          | `references/pytest-core.md`: 17–373; `references/mocking-and-integration.md`: 374–747               |
| rust-patterns   | 1–20, 457–498          | `references/ownership-errors-types.md`: 21–227; `references/concurrency-unsafe-modules.md`: 228–456 |
| rust-testing    | 1–27, 420–473          | `references/unit-and-integration.md`: 28–211; `references/advanced-testing.md`: 212–419, 474–501    |
| ts-patterns     | 1–44, 724–816          | `references/types-errors-modules.md`: 45–373; `references/async-runtimes-tooling.md`: 374–723       |
| ts-testing      | 1–33, 602–700          | `references/vitest-core.md`: 34–325; `references/advanced-testing.md`: 326–601, 701–762             |

No committed one-off test. Parent temporary check: `/tmp/opencode/check-yan704.py` (outside repository). No commands/agents/rules/metadata/generator/installer changes needed. Parent regeneration may change same 24 files in each of `.cursor-plugin/skills/`, `.codex-plugin/ycc/skills/`, `.opencode-plugin/skills/`; researcher does not write those.

## Before/after acceptance measurements

Baseline eligible initial skill surface: **5,564 lines / 142,182 bytes**. Proposed aggregate <=**2,000 lines**: reduction >=**3,564 lines (64.05%)**. This is a budget until parent measures completed files, not achieved evidence or token/startup savings.

Split retains **766 original lines inline + 4,798 original lines in references = 5,564 original lines (100%)**. All original sections/content retained, metadata included. Added summaries/headings explain any total disk growth. Measure final UTF-8 bytes separately; no byte-savings forecast. Largest original moved reference chunk: 392 lines, below ~500-line policy. Eight discovery descriptions total **4,585 characters**, unchanged; eight skills/eight commands remain. Reading references can restore original context volume; no promise of savings for full-topic requests.

## Build sequence and parent-owned evidence path

1. Preserve baseline snapshot and exact eight command files/frontmatters; use pinned git objects, not another writer's files.
2. Move complete original sections to named references; build <=250-line primers with critical rules first and conditional reads.
3. Temporary stdlib check asserts baseline sections/ranges retained unchanged at assigned destinations, identical frontmatter/commands, eight public names, line budgets, valid relative links/read conditions, balanced fences. Check mapping covers every baseline line, not only headings or representative phrases.
4. Record actual per-file/aggregate lines and UTF-8 bytes before/after. Reproduce overlap table above. Do not assert success from design budgets.
5. Parent obtains required code-reviewer review for implementation, then runs `python3 /tmp/opencode/check-yan704.py`, `./scripts/sync.sh`, `./scripts/validate.sh`. Investigate unrelated generated drift separately; inventory/README expected unchanged.
6. Live checks where available: eight skills; Claude/opencode commands still invoke matching skill; conditional reference load for Go cancellation/Python mocking; Rust unsafe invariant retained without reference read; TS type-level/E2E boundary. Mark unavailable runtime checks honestly. OpenCode automatic reference loading undocumented: demonstrate explicit read rather than assume it.

Evidence anchors: `CLAUDE.md` source/generated boundary and ~500-line cap; `CONTRIBUTING.md:131–167` skill/command distinction; `RELEASING.md` trunk-only model; `ycc/rules/README.md:82–87` standards versus depth. Recursive copy/transforms: `scripts/generate_cursor_skills.py:176–225`, `generate_codex_skills.py:101–175`, `generate_opencode_skills.py:113–187`. Invocation rewrites in cursor skill generator, `generate_codex_common.py`, `generate_opencode_common.py`, and opencode command generator. Existing skill validators establish drift/frontmatter/content policy, not lossless retention or conditional read behavior; temporary check fills those gaps.

## Risks and approval gates

- YAN-712 fixed by `1fc24d5` / #194; `validate-cursor-rules.sh` rejects unknown source-rule skill citations. Keep public entrypoints, do not repeat dangling-reference work.
- Existing sample accuracy debt: Go sync.Pool returns buffer memory after put; TS coverage says no extra dependencies; Python rules prefer black/isort while skill prefers ruff format; version-sensitive snippets. Lossless relocation is not correctness certification. Do not copy questionable samples into new critical rules; semantic fixes require separate scope/version evidence.
- Summaries can accidentally weaken testing contracts or expand optional patterns into mandates; review against retained original sections.
- Public removal/rename, exposure disabling, discarded content, runner migrations, or altered coverage requirements require explicit user approval. None granted; not part of plan.
