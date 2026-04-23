# Review Checklist (Shared Reference)

> Canonical review checklist, severity rubric, parallel-reviewer roster, and
> standard findings format. Consumed by `code-review` (local + PR modes)
> and `quick-review`. Skills that delegate here MUST NOT duplicate the
> content below — reference this file instead.

---

## Severity Rubric

| Severity     | Meaning                                     | Action                  |
| ------------ | ------------------------------------------- | ----------------------- |
| **CRITICAL** | Security vulnerability or data loss risk    | Must fix before merge   |
| **HIGH**     | Bug or logic error likely to cause issues   | Should fix before merge |
| **MEDIUM**   | Code quality issue or missing best practice | Fix recommended         |
| **LOW**      | Style nit or minor suggestion               | Optional                |

Findings are grouped by severity in the artifact under `### CRITICAL`,
`### HIGH`, `### MEDIUM`, `### LOW`, in that order.

---

## Local / Quick Review — Single-Pass Checklist (Path A)

Applied to uncommitted changes on `HEAD`. Read each changed file in full.

**Security Issues (CRITICAL):**

- Hardcoded credentials, API keys, tokens
- SQL injection vulnerabilities
- XSS vulnerabilities
- Missing input validation
- Insecure dependencies
- Path traversal risks

**Code Quality (HIGH):**

- Functions > 50 lines
- Files > 800 lines
- Nesting depth > 4 levels
- Missing error handling
- `console.log` statements
- TODO/FIXME comments
- Missing JSDoc for public APIs

**Best Practices (MEDIUM):**

- Mutation patterns (use immutable instead)
- Emoji usage in code/comments
- Missing tests for new code
- Accessibility issues (a11y)

---

## PR Review — Single-Pass Checklist (Path A, 7 Categories)

Applied to PR head-revision file contents. Each category is independent —
a single finding may touch several.

| Category               | What to Check                                                                 |
| ---------------------- | ----------------------------------------------------------------------------- |
| **Correctness**        | Logic errors, off-by-ones, null handling, edge cases, race conditions         |
| **Type Safety**        | Type mismatches, unsafe casts, `any` usage, missing generics                  |
| **Pattern Compliance** | Matches project conventions (naming, file structure, error handling, imports) |
| **Security**           | Injection, auth gaps, secret exposure, SSRF, path traversal, XSS              |
| **Performance**        | N+1 queries, missing indexes, unbounded loops, memory leaks, large payloads   |
| **Completeness**       | Missing tests, missing error handling, incomplete migrations, missing docs    |
| **Maintainability**    | Dead code, magic numbers, deep nesting, unclear naming, missing types         |

---

## Parallel Reviewer Roster (Path B / Path C)

Three standalone `code-reviewer` sub-agents (Path B) or agent-team teammates
(Path C). The **focus split** differs between local/quick and PR modes because
local mode has a narrower category set.

### Local / Quick Mode Roster

| Reviewer               | Focus           | Checklist Items                                                                                                               |
| ---------------------- | --------------- | ----------------------------------------------------------------------------------------------------------------------------- |
| `correctness-reviewer` | Code Quality    | Functions > 50 lines, files > 800 lines, nesting > 4 levels, missing error handling, `console.log`, TODO/FIXME, missing JSDoc |
| `security-reviewer`    | Security Issues | Hardcoded credentials/keys/tokens, SQL injection, XSS, missing input validation, insecure deps, path traversal                |
| `quality-reviewer`     | Best Practices  | Mutation patterns, emoji in code/comments, missing tests, accessibility (a11y)                                                |

### PR Mode Roster

| Reviewer               | Categories                             | What to Check                                                                                                                                                             |
| ---------------------- | -------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------- |
| `correctness-reviewer` | Correctness, Type Safety, Completeness | Logic errors, off-by-ones, null handling, edge cases, race conditions, type mismatches, unsafe casts, `any` usage, missing generics, missing tests, incomplete migrations |
| `security-reviewer`    | Security, Performance                  | Injection, auth gaps, secret exposure, SSRF, path traversal, XSS, N+1 queries, missing indexes, unbounded loops, memory leaks, large payloads                             |
| `quality-reviewer`     | Pattern Compliance, Maintainability    | Project conventions (naming, file structure, error handling, imports), dead code, magic numbers, deep nesting, unclear naming, missing types                              |

Each reviewer prompt MUST include:

1. The list of changed files (mode-specific: `git diff --name-only HEAD` for
   local/quick; PR number + head revision + changed-file list for PR).
2. Relevant context (AGENTS.md rules, PRP artifacts, PR description) — PR mode only.
3. Its assigned focus / categories and what to check (from the appropriate table
   above).
4. The severity rubric.
5. A directive to return findings in the **Standard Findings Format** below.

---

## Standard Findings Format (Reviewer Output)

Each parallel reviewer returns findings in this shape (pre-merge, before
finding-ID assignment):

```markdown
## Findings

### CRITICAL

- `file.ts:42` — [description] [category]
  - Suggested fix: [fix]

### HIGH

- ...

### MEDIUM

- ...

### LOW

- ...
```

The `[category]` tag applies to PR mode; local/quick mode may omit it (the focus
split already implies a category).

---

## Merge Procedure (Path B / Path C)

After all 3 reviewers return:

1. Combine by severity (CRITICAL first, then HIGH, MEDIUM, LOW).
2. De-duplicate findings at the same `file:line` (if two reviewers flagged the
   same issue, keep the more severe one and annotate which reviewers concurred).
3. Sort within each severity by file path.
4. Attach the reviewer source to each finding (`[correctness]`, `[security]`,
   `[quality]`) for traceability.

Pass the merged findings to the REPORT phase as if they came from a single-pass
review.

---

## Finding Artifact Fields

After merging, each finding is promoted to an artifact-format block with these
fields. The `[F###]` ID is assigned sequentially ordered by severity (CRITICAL
first), then by file path. Status is always `Open` on first write.

```markdown
- **[F001]** `file:line` — description
  - **Status**: Open
  - **Category**: <category>
  - **Suggested fix**: <fix>
```

See `/code-review` → "Review Artifact Format" for the full artifact schema
(Header, Summary, Findings, Worktree Setup, Validation Results, Files Reviewed).
