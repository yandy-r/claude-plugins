# Innovation: Novel Hypotheses from Persona Recombination

**Agent**: innovation-agent (Asymmetric Research Squad, synthesis phase)
**Method**: Combinatorial synthesis across 8 persona findings — not a re-ranking of any
persona's punch list, but artifacts that only emerge at the _intersections_.
**Date**: 2026-04-20
**Grounding**: Every hypothesis cites the persona(s) it emerges from, the concrete
failure mode it prevents (traced to a verified research finding), and a testable
prediction that would validate or refute it.

> Epistemic stance: this document aims for _inventive but grounded_. Each proposal
> maps to a failure mode the persona research documented or a gap the crucible /
> contradiction-mapping made load-bearing. Where a proposal speculates beyond the
> research base, it is marked **[SPECULATIVE]** and the speculation is named.

---

## Executive Summary

Eight personas converged on an unusually narrow positive recommendation: **hooks +
3-5 workflow-shaped skills**, not per-vendor trees. That convergence is a gift — it
frees this synthesis from re-litigating the dosage question and lets us instead
ask: _what artifacts become visible only when you look at the persona cross-product,
not any single persona?_

The recombination produces **six novel hypotheses** that are genuinely absent from
every individual persona's proposal list, plus a seventh meta-pattern that reframes
the authoring economics of the whole bundle. The two highest-value emergents:

1. **`ycc:sunset-review`** (Systems-thinker × Negative-space) — the one meta-skill
   whose existence _reduces_ future descriptor pollution. No individual persona
   proposed it because no individual persona was looking for skills that displace
   other skills. It is the single most anti-fragility-positive addition available.

2. **`ycc:archive-as-a-service`** (Historian × Futurist) — RANCID's 1997
   diff-archive-rollback discipline, rebuilt as an MCP-native workflow that
   generates a verifiable immutable audit package from any tool trace. This is
   what the archaeologist's P0 skills become when you stop treating "MCP" and
   "discipline" as opposites and start treating them as a **transport + content**
   pair.

The recombinations are ordered by _expected impact × feasibility_, not by persona
exotic-ness. Each is a specific artifact proposal with a form, a failure mode, and
a falsifiable prediction.

**Meta-insight**: the persona findings produced a rich "what to build" consensus,
but _none_ surfaced the question of **what, exactly, makes a ycc artifact
retire-able**. This is the one gap that spans all 8 personas and that the
systems-thinker's 70-90 skill tipping point makes urgent. Three of the six
hypotheses below address authoring economics rather than infra domains, and that
is the **structural finding** of this synthesis.

---

## Novel Hypotheses

### NH1 — `ycc:sunset-review`: The Meta-Skill That Displaces Skills

**Form**: Command + skill (`/ycc:sunset-review` → invokes `ycc:sunset-review` skill).

**Persona combination**: Systems-thinker × Negative-space. Also draws on analogist
(CNCF Graduated → Archived lifecycle).

**Why it only emerges from the cross-product**:

- Systems-thinker identified the 70-90-skill fragility cliff (E17, crucible) and the
  B2 context-pollution loop, but proposed meta-skills for _routing_ (LP #6), not for
  _removal_.
- Negative-space enumerated 12+ absences but treated every absence as a candidate
  for addition, never for removal.
- CNCF has a concrete archival pathway (systems-thinker cites CNCF Graduated
  criteria; archaeologist's Opsware / BladeLogic history makes clear that tools
  outlive their usefulness), but no persona asked "what is `ycc`'s analog to CNCF
  Archived?"

The recombination observation: **the highest-leverage new artifact is the one that
reduces future descriptor bulk**. Every persona's build list implicitly assumed skills
are additive; this one treats them as _reversibly additive_ for the first time.

**What it does**:

1. Scans `ycc/skills/` and parses each SKILL.md's descriptor/frontmatter.
2. Cross-references a local invocation log (optional — see NH6 below) or asks the
   owner for each skill: "used in the last 90 days? in the last year?"
3. For skills with zero invocations AND no recent author edits, emits a _sunset
   proposal_ with three options: (a) keep + document why, (b) merge into a sibling
   skill (identifies candidate parents by overlap), (c) archive (move to
   `ycc/skills/_archive/` with a redirect note).
4. Produces a markdown report at `docs/reviews/sunset-{date}.md` — ready to
   turn into a commit or PR.
5. Optional: emits a GitHub issue with the `type: refactor` label per retired skill.

**Concrete failure mode it prevents**:

- **B2 context-pollution loop becoming dominant** (systems-thinker, E17). Every
  unused skill's descriptor line still lives in the system prompt on every
  invocation; 45 skills × 100 tokens = 4.5 kT persistent bulk per session today,
  compounding with every addition. A skill that isn't invoked is a pure tax.
- **Booklore-pattern scope collapse** (historian, E2). A one-maintainer bundle that
  never retires content accumulates maintenance surface monotonically; sunset
  discipline is the only mechanism that keeps `ycc` lean without refusing all
  additions.

**Testable prediction**: After one run of `/ycc:sunset-review` against the current
bundle, ≥5 of the 45 skills will be flagged as "used <3 times in 90 days by the
maintainer" OR "superseded by a sibling skill's scope creep." If <3 are flagged,
the hypothesis that `ycc` needs sunset discipline _now_ is refuted; the skill can
ship but will be low-value until scale forces it. If ≥5 are flagged, the skill
pays for itself on its first execution.

**Potential impact**: **High.** Indirectly protects every _future_ addition by
giving the maintainer a defensible review cadence. Unlocks the crucible's H4
(workflow + hooks) without forcing H2 (zero build) — because an additive bundle
that also subtracts stays bounded.

**Feasibility**: **S** (small — pure Python/bash over the existing source tree, no
external deps, ~200-400 lines). The hardest part is the _usage-count_ data source;
v1 can prompt the maintainer, v2 can integrate NH6's telemetry.

**Why not an agent**: deterministic work (file walks, descriptor parsing, git log
scanning) dominates. Judgment is "which cluster does this skill belong to?" and
"did I actually use it?" — both belong to the owner, not a reasoner.

---

### NH2 — `ycc:archive-as-a-service`: RANCID Rebuilt on MCP Transport

**Form**: Skill + `_shared/scripts/cook-diff.sh` + optional PostToolUse hook.

**Persona combination**: Historian × Futurist. Archaeologist provides the content
discipline (cook-and-diff, `router.db`, "rollback is the plan"); futurist provides
the transport shape (MCP as substrate, NL→IR→validate spine).

**Why it only emerges from the cross-product**:

- Historian observed RANCID (1997) is "still running in production in 2026" but
  framed this as a historical archetype to be honored, not as a _substrate for
  new work_.
- Futurist rejected vendor-CLI wrappers (§10.7) in favor of MCP consumption but
  did not connect MCP to the archaeologist's specific P0 list.
- Contradiction #2 in contradiction-mapping ("MCP substrate vs. screen-scrape
  forever") flagged this as irreducible. It isn't. The two map cleanly onto a
  **content/transport split**: RANCID's _discipline_ is the content; MCP is the
  transport; the irreconcilability dissolves once you stop conflating them.

The recombination observation: RANCID's read-only, diff-centric, git-as-storage
archetype is **transport-agnostic**. It was built on Expect because Expect was the
available transport in 1997. The same discipline on MCP + git + a typed IR is
not a port of RANCID — it's the **correct implementation** of RANCID for 2026.

**What it does**:

1. Runs on a schedule (cron skill) or an event trigger (syslog `%SYS-5-CONFIG_I`,
   webhook, or manual).
2. For each device in a flat `network.tsv` (router.db-compatible), pulls current
   state via the vendor's MCP server (when present) or SSH/NETCONF fallback.
3. Applies `_shared/scripts/cook-diff.sh` — strips volatile fields per a
   vendor-keyed regex library (chassis temp, MAC reorder, session IDs, nonces,
   timestamps). This is verbatim RANCID's 1997 discipline.
4. Commits to a git-backed archive repo with a provenance stamp: {model, prompt
   hash, tool-call trace ID, timestamp, operator, MCP server version}.
5. Emits a unified diff as a SOX/HIPAA/PCI-compliant **evidence bundle** — the
   archive itself IS the rollback (historian Insight 6, archaeologist's "rollback
   is the plan").

**Concrete failure mode it prevents**:

- **"Someone changed the firewall last Tuesday"** (archaeologist, P0 #1 failure
  mode). Polling-based drift + cooked diff is still the only detection mechanism
  that catches out-of-pipeline changes.
- **Evidence-bundle absence for regulated industries** (negative-space, gap #2 +
  #12). SOX 7-year / HIPAA 6-year / PCI 3-year retention requires immutable
  provenance. No `ycc` skill produces this today.
- **Adversarial telemetry risk** (futurist, E25/AIOpsDoom). A cooked,
  schema-validated, git-committed artifact resists telemetry poisoning better than
  raw log scraping.

**Testable prediction**: In a live trial across 5 devices over 30 days, at least
one "genuine drift" event (out-of-pipeline change) will be detected that no other
mechanism surfaced. If zero drift events are detected in 30 days with real device
fleet movement, the owner's workflow probably doesn't need this skill and the
contrarian's "hooks alone" hypothesis wins.

**Potential impact**: **High** for owners with any regulated/audited workload; **
Medium** for hobby/homelab. Directly closes the largest documented cross-vendor
workflow gap (E8 in crucible).

**Feasibility**: **M** — the skill is small (SKILL.md + cook-diff.sh + cron
wrapper) but the `cook-diff.sh` vendor regex library requires per-vendor research.
Ship with Cisco IOS-XE + Junos + FortiOS + PAN-OS as seed (matches owner's stated
vendor list); grow via community PRs. The regex library is the real work; the
Claude-side surface is thin.

**Why not a pure hook**: drift detection is scheduled / event-driven / long-running;
hooks are synchronous per-tool-call. This is the kind of workflow Gawande's
analogist would classify as a "communication checklist that must produce an
artifact," not a choke-point block.

---

### NH3 — `ycc:skill-fitness`: The Plugin-Level CNCF-Adoption Test

**Form**: Skill + `/ycc:skill-fitness` command + `.ycc-fitness.json` metadata
sidecar per skill.

**Persona combination**: Analogist × Contrarian × Systems-thinker.

**Why it only emerges from the cross-product**:

- Analogist proposed the "used ≥3 times in last 60 days while doing real work"
  CNCF-adoption test (E16 + analogist Insight 3), but as a _mental heuristic_, not
  a shipped artifact.
- Contrarian argued prose skills create false confidence (E3/E13), but stopped
  short of proposing a quality-signal taxonomy within `ycc`.
- Systems-thinker noted R1 (virtuous authoring loop) weakens on skills the
  maintainer touches infrequently (E27), but treated this as an observation, not
  an intervention.

The recombination observation: the three personas identified the same gap from
three angles — the absence of a _lifecycle tier_ that distinguishes production-
ready skills from experimental ones. Analogist called this CNCF Sandbox /
Incubating / Graduated; contrarian called it "trust earned over time";
systems-thinker called it "R1 feedback strength per skill." All three are the same
artifact.

**What it does**:

1. Adds a frontmatter field to every skill: `fitness: sandbox | incubating |
graduated | legacy`.
2. Ships a `/ycc:skill-fitness` command that:
   - Lists all skills with their current tier.
   - Proposes promotions (sandbox → incubating after 3+ real-world invocations;
     incubating → graduated after 60 days + 10 invocations with zero owner-reported
     corrections).
   - Proposes demotions (graduated → legacy after 90 days without invocation).
   - Validates that each skill's description is honest about its tier (a
     `graduated` skill cannot be marked sandbox-quality).
3. Claude Code runtime reads the tier and weights skill selection: graduated
   skills are preferred; sandbox skills require an explicit invocation or a
   configured "experimental mode" flag.
4. Surfaces tiers in the marketplace.json display so external users can make
   informed choices.

**Concrete failure mode it prevents**:

- **"Half-built vendor skill creates surprise failure"** (analogist Crossing-the-
  Chasm). Pragmatist users don't want to discover, mid-incident, that a skill is
  experimental; they want to know _before_ they invoke it.
- **Descriptor keyword stuffing (R3 loop)** (systems-thinker). A lifecycle tier
  provides a quality signal that doesn't require rewriting descriptions to
  compete for attention.
- **Contrarian's false-confidence warning** (E3). Sandbox tier forces honesty
  about what the skill actually does.

**Testable prediction**: Within 30 days of shipping, at least 3 currently-shipped
skills will be auto-demoted from graduated to legacy based on invocation count. If
zero demotions occur, either (a) every skill is genuinely in use (surprising —
would refute systems-thinker's E17 estimate) or (b) the maintainer manually
overrode demotions (which is the escape hatch; still a signal worth capturing).

**Potential impact**: **Medium-High.** Doesn't fix a single infra-domain gap, but
rewires the authoring economics of the whole bundle. Pairs naturally with NH1
(sunset-review) — fitness flags candidates, sunset removes them.

**Feasibility**: **S-M.** Frontmatter extension is trivial; tier-based weighting at
runtime depends on harness cooperation (Claude Code honors tier → low effort;
Cursor/Codex/opencode may not yet → ship as documentation-only in v1, runtime
integration in v2).

**Why not just a doc?**: a doc decays silently; a skill with deterministic
promotion/demotion rules is the Gawande communication checklist analogist
endorses.

---

### NH4 — `ycc:blast-radius-reasoner`: An Orient-Phase Agent That Refuses to Act

**Form**: Thin agent + PreToolUse hook invocation.

**Persona combination**: Analogist (OODA Orient-phase amplification) × Contrarian
(hooks > skills for safety) × Negative-space (zero blast-radius labels in `ycc`).

**Why it only emerges from the cross-product**:

- Analogist identified the **Orient phase** as the empty niche where AI amplifies
  most and **Act phase** as where tools already win (analogist §OODA, §Choke
  points). This shaped the "reason, don't act" framing but stopped at shape.
- Contrarian argued hooks > skills for safety and rejected agents-that-act
  (disconfirmation A/B for K8s/networking). But this leaves a gap: _how does the
  reasoning-about-blast-radius happen?_ A deterministic hook cannot estimate blast
  radius from a `kubectl apply -f manifest.yaml` or an ACL change.
- Negative-space documented the complete absence of blast-radius labels on any
  `ycc` command (E8, negative-space Friction Point #1-7).

The recombination observation: the right artifact is an **agent whose tool
permissions exclude every write tool** — it can read, reason, call MCP tools in
read-only modes, but cannot execute the change it reasons about. It IS the Orient
phase, scoped out by permission to never reach Act. This combines analogist's
framework (Orient is the gap) with contrarian's safety doctrine (permissions >
prompts) with negative-space's observation (blast-radius is unimplemented).

**What it does**:

1. Triggered by a PreToolUse hook on any "infra-touching" tool call (configurable
   regex: `kubectl apply|delete|drain`, `terraform apply`, `ansible-playbook`,
   `ssh.*config`, `gcloud compute instances`, `aws ec2 terminate`).
2. Invokes `ycc:blast-radius-reasoner` subagent with read-only MCP access.
3. The subagent produces a structured blast-radius report: {scope: {resources
   affected, neighbors, downstream systems}, reversibility: {rollback available,
   rollback latency, data-loss risk}, HITL requirement: {low | medium | high}}.
4. Emits the report to the transcript and a persistence path (`docs/blast/`).
5. Non-blocking by default; can be made blocking for scope=production via
   settings. The hook _always_ returns exit 0 unless the user has configured
   "require acknowledgment."

**Concrete failure mode it prevents**:

- **AWS Kiro / Meta SEV1-class incidents** (contrarian E9, futurist E9). A
  reasoning pass before destructive action is the specific intervention AWS's
  post-mortem called for.
- **Anthropic's own "approval-shaped evidence without blast-radius check"**
  (negative-space §6, citing Anthropic auto-mode blog). The agent structurally
  cannot skip the blast-radius check because it is the only thing the agent is
  permitted to do.
- **Agent-write escalation risk** (systems-thinker §B3, contrarian §Kiro). The
  Gawande split becomes enforceable: reasoning in the skill/agent layer, action
  in the human/MCP layer.

**Testable prediction**: Over 30 days of real owner use, the reasoner will
surface at least one blast-radius fact the owner _did not already know_ before
invoking it — something about cross-resource dependencies, a hidden downstream
system, or a rollback latency that was underestimated. If zero surprises occur,
the Orient-phase gap isn't as open as the analogist claims; the skill becomes
noise.

**Potential impact**: **High** — this is the single artifact that converts the
crucible's H3 (hooks-only) into H4 (workflow + hooks) without adding a skill. The
agent is the reasoning layer; the hook is the enforcement.

**Feasibility**: **M.** Agent frontmatter is trivial; the read-only MCP discipline
requires careful permission scoping (exclude every `Bash`/`Edit`/`Write` tool);
the blast-radius schema needs vendor-domain-specific knowledge to be useful
(sandbox tier at launch, graduated after real-world tuning).

**Why not a skill?**: skills expand into the context window for every invocation.
An agent is invoked on-demand by the hook; its descriptor is read once by the
hook, then it runs in a subagent context. This matches systems-thinker's LP #5
(rules about rules) and avoids descriptor bulk.

---

### NH5 — `ycc:mop-as-policy`: Executable MOPs from Natural Language

**Form**: Skill + command + `docs/mops/{date}-{change}.md` template + OPA/Rego
policy-lint hook.

**Persona combination**: Archaeologist × Futurist × Analogist.

**Why it only emerges from the cross-product**:

- Archaeologist proposed `/ycc:mop` as a P0 revival (archaeologist P0 #2) — a
  structured MOP with rollback commands, blast radius, sign-off roles.
- Futurist proposed the NL→IR→validate→deploy→verify spine (§10.1) but didn't
  connect it to the MOP artifact class.
- Analogist's Gawande stack (skill + script + hook, §Gawande) suggested _how_
  MOPs should be layered but not _what_ MOPs should contain.

The recombination observation: the archaeologist's MOP IS the futurist's spine,
instantiated per change. "Method of Procedure" is just the 1970s military name for
"typed intermediate representation with HITL gates and rollback commands." Once
you see that, the MOP becomes executable rather than advisory — a document that
_validates itself_.

**What it does**:

1. Takes a proposed change (diff, PR, NL intent) and produces a MOP at
   `docs/mops/{date}-{change-name}.md` with a **typed YAML frontmatter** covering:
   - Objective (NL)
   - Scope (typed list of resources)
   - Prerequisites (typed list of preconditions, each runnable)
   - Pre-check commands (executable)
   - Apply steps (executable, with IR-typed operations)
   - **Rollback commands (mandatory, executable, tested against twin if available)**
   - Post-check commands (executable)
   - Completion criteria (assertions over post-check output)
   - Blast-radius summary (pulled from NH4 if present)
   - Sign-off role(s)
2. The MOP is _policy-linted_ against `mop-policy.rego`:
   - Rejects MOPs with missing rollback commands (the archaeologist's #1
     forgotten wisdom).
   - Rejects MOPs with pre-check but no post-check (the canonical failure mode).
   - Requires explicit blast-radius even if "low."
3. The MOP can be _executed_ by a companion `/ycc:mop-run` command (deferred —
   v2), but v1 is reviewer-friendly advisory.

**Concrete failure mode it prevents**:

- **"PR was approved but nobody wrote down how to undo it"** (archaeologist P0 #2
  literal quote). This is the canonical MOP-less failure.
- **NL→config hallucination** (contrarian E3, futurist Xumi/Clarify/NYU). An NL
  intent that compiles to a typed IR (MOP operations) is auditable; raw vendor
  CLI in chat is not.
- **Change-window violations** (archaeologist P1 #7, negative-space gap). The MOP
  frontmatter can include a `change-window` field that the policy-lint rejects
  if the MOP's filename timestamp falls outside the repo's declared windows.

**Testable prediction**: Of the next 10 non-trivial infra PRs the owner creates,
the MOPs written by this skill will catch at least 2 rollback-absent or
post-check-absent PRs that would have slipped into main without the policy-lint.
If zero PRs trip the policy-lint, either (a) the owner is already disciplined
(refuting the archaeologist's "still happens in 2026" claim for this user) or (b)
the policy rules are too lax.

**Potential impact**: **High** for regulated workflows; **Medium** for general
dev. Combines archaeologist's P0 value (MOP ritual) with futurist's durability
(the MOP _is_ the IR the 2027 vendor MCPs expect as input). This is the load-
bearing artifact for "bridging to 2027" without rewriting in 2028.

**Feasibility**: **M.** MOP template + policy rules are small; the value is in
the discipline of making rollback mandatory in frontmatter. OPA/Rego dependency
is a real addition but OPA is already widely present in infra toolchains.

**Why layered skill + policy + (future) run-command**: Gawande three-layer stack.
Skill = judgment (how to write a MOP). Policy = task checklist (is this MOP
complete?). Runner = communication checklist (enforced pause at each step).

---

### NH6 — `ycc:skill-telemetry`: The Data Source Sunset Needs

**Form**: Local append-only log file + PostToolUse hook + `_shared/scripts/log-
invocation.sh`.

**Persona combination**: Negative-space × Systems-thinker × Futurist.

**Why it only emerges from the cross-product**:

- Negative-space documented the complete absence of usage telemetry in
  `ycc` (negative-space §Knowledge Gaps — "actual adoption rates ... telemetry
  does not exist").
- Systems-thinker identified that every sunset/fitness signal requires a usage
  data source (B1 loop analysis, LP #12 vs #5 framing).
- Futurist warned that AIOpsDoom-style adversarial telemetry is a real 2027
  threat (futurist §5, E25) — so the telemetry must be _local, append-only,
  signed_, not a cloud callback.

The recombination observation: the data source NH1 (sunset) and NH3 (fitness) need
**must exist before those skills ship usefully**, and it must be **attacker-
resistant by design** (no cloud callback, no writable remote endpoint). This is a
primitive, not a skill, but it's the enabling primitive for three other proposals.

**What it does**:

1. A PostToolUse hook on Claude's Skill tool appends a single line to
   `~/.ycc/invocations.log` (or repo-local `.ycc/invocations.log` for project-
   scoped bundles). Line format: `{iso-timestamp} {skill-id} {invocation-hash}`.
2. The log is **append-only** (set immutable bit if OS supports it) and
   **signed on rotate** (log rotation produces a gzipped, hash-chained archive
   that new entries can't falsify).
3. `_shared/scripts/log-invocation.sh` parses the log for NH1/NH3/NH4.
4. A `/ycc:telemetry-audit` command verifies chain integrity and reports summary
   stats (top-N invoked skills, last-invoked per skill, orphan skills with zero
   invocations).

**Concrete failure mode it prevents**:

- **"Actual adoption rates of Claude Code plugins [is unknowable]"** (negative-
  space knowledge gap). Without local telemetry, sunset/fitness are guesswork.
- **Systems-thinker's R1 loop invisibility** (E27). The maintainer cannot tune R1
  strength per skill without per-skill invocation data.
- **Adversarial telemetry risk** (futurist E25). A cloud callback is the adversary-
  visible attack surface; local-only, hash-chained logs are not.

**Testable prediction**: After 14 days of normal use, the log will show a
**bimodal distribution**: a handful of skills (~5-8) with heavy invocation, a long
tail with zero or one. If instead the distribution is uniform, the R1 loop is
stronger than systems-thinker assumed and B2 is further away. Either outcome is a
useful calibration data point.

**Potential impact**: **High as an enabler** (unlocks NH1, NH3, NH4's hook
routing). **Low as a standalone artifact.** This is infrastructure for the
infrastructure.

**Feasibility**: **S.** ~50-100 lines of bash. The discipline question is where to
emit the hook — it has to be installable in the user's `~/.claude/settings.json`
via ycc's own `hooks-workflow` skill.

**Why a hook, not a skill?**: hooks are the deterministic enforcement layer.
Telemetry _must_ fire on every invocation or the dataset is biased. A skill
could be skipped; a hook cannot.

---

### NH7 — `ycc:maintainer-mode`: Coach-Mode and Senior-Mode as a Single Flag

**Form**: Frontmatter field + per-skill conditional reference loading.

**Persona combination**: Negative-space (junior pipeline under-served) × Analogist
(whole-product for pragmatists) × Historian (operator-not-developer mental
model). [SPECULATIVE] in its downstream-audience claims.

**Why it only emerges from the cross-product**:

- Negative-space documented that **no `ycc` skill is coach-mode** (E28, negative-
  space §Junior pipeline), while the junior network engineer pipeline is exactly
  the under-served demographic.
- Analogist's Crossing-the-Chasm observation was that pragmatists need whole
  products, but a pragmatist at a junior level needs a _different_ whole product
  than a pragmatist at a senior level.
- Historian's "network engineers are not developers; they want declarative, not
  procedural, not ceremonious" observation (E14) implies the operator UX needs
  its own mode, distinct from the developer UX most `ycc` skills assume.

The recombination observation: a single frontmatter flag `mode: coach | peer |
senior` on skill invocations switches the reference-loading behavior without
multiplying skill count. `ycc:go-patterns` with `mode: coach` shows three
alternatives considered and why the chosen one won; same skill with `mode:
senior` skips the explainer and just emits the change. One skill, three
audiences, one descriptor.

**What it does**:

1. Adds `default-mode` to each skill's frontmatter and a `--mode` flag on
   invocations.
2. Skill references are tagged in their body with `<!-- mode: coach -->` and
   `<!-- mode: senior -->` guards; the runtime (or a simple preprocessor) strips
   non-matching blocks before expanding the skill.
3. A `ycc:maintainer-mode` skill documents the convention and provides a lint
   that warns if a senior-only skill lacks coach-mode content (or vice versa).
4. Default mode: `peer` — the current behavior. Coach and senior are opt-in.

**Concrete failure mode it prevents**:

- **"Senior engineers absorb AI output; juniors lose the error-recognition
  muscle"** (negative-space §Cultural, citing Cisco AI babysitter framing).
- **Half-product for pragmatist juniors** (analogist Crossing-the-Chasm).
- **Operator-vs-developer mental model mismatch** (historian Insight 2).

**Testable prediction**: **[SPECULATIVE]** If the bundle ever has a non-maintainer
audience, coach-mode invocation requests will appear in issue trackers or
usage logs; if it doesn't, coach-mode is unused and NH7 becomes a candidate for
NH1's sunset review. This is the one NH that deliberately embeds its own
falsifier.

**Potential impact**: **Medium-High** if `ycc` has a downstream audience, **Low-
Medium** if it is primarily the maintainer's tool. This NH is intentionally
contingent on resolving Contradiction #8 from contradiction-mapping (owner's
monthly weighting + audience mix).

**Feasibility**: **S-M.** Frontmatter + comment-guard convention is minimal. The
per-skill content triples _authoring_ work (coach + peer + senior variants), so
this NH only pays off on keystone skills (analogist's keystone-vs-specialist
framing) — maybe 5-8 of the 45 total, not all.

**Why a convention, not a new skill per audience?**: a skill-per-audience is the
Backstage trap (analogist). A convention with mode guards is the JetBrains post-
split monorepo pattern done right.

---

## Innovative Approaches (Meta-Patterns)

These are not discrete artifacts but **authoring patterns** that the recombination
surfaces. Each could be applied retroactively to existing skills as well as to new
ones.

### IA1 — The Three-Layer Gawande Default

Every new skill proposal must answer three questions before it ships:

1. What **judgment** does the skill provide? (skill = progressive-disclosure doc)
2. What **checklist** enforces it? (script = deterministic runnable)
3. What **pause** makes the user consider it? (hook = choke-point enforcement)

If all three exist, the skill is a complete Gawande stack (analogist). If only one
exists, the proposal is incomplete — **not automatically rejected**, but flagged
for the bundle-author skill to prompt: "you have a skill but no hook; is the
determinism absent because the task is inherently adaptive, or because you haven't
written the script?" This is the analogist's Gawande trio (E15, E30) made
operational in the authoring tooling.

**Source**: Analogist × Archaeologist × Contrarian. The recombination: every
persona's safety recommendation was a _shape_ (skill vs script vs hook); this
pattern makes the shape a checklist applied to _every_ new addition.

**Implementation**: extends `ycc:bundle-author` with a three-layer prompt.

### IA2 — Content/Transport Split

No skill shall be named after a transport (no `ycc:cisco-ios-cli`,
`ycc:kubectl-api`, `ycc:ssh-netmiko`). All skills shall be named after a
**workflow or discipline**, and the transport shall be an implementation detail
inside the skill (via MCP when available, CLI/SSH when not).

**Source**: Historian × Futurist. The recombination: the historian's "vendor
tooling half-life is 5-10 years" (E21) and the futurist's "MCP is substrate"
(§10.2) collapse into the same naming rule: **don't encode the transport in the
identifier**. The content outlives the transport by decades; naming after the
transport inherits the transport's lifecycle risk.

**Implementation**: update `ycc:bundle-author` + CONTRIBUTING.md with this naming
rule. Apply retroactively to any existing skill names that violate it (none at
present — the existing `git-workflow` / `plan-workflow` / `code-review` / `bundle-
release` all pass this test, which is itself a validation of the rule).

### IA3 — The Personal-Use Test Before Incubation

No skill graduates from sandbox (NH3) until the maintainer has invoked it **3+
times in 60+ days on real work** (analogist's CNCF-adoption test,
E16). This is automatically verifiable via NH6 (skill-telemetry).

**Source**: Analogist × Contrarian × Systems-thinker. The recombination: the CNCF
adoption criterion (analogist), the contrarian's "did the maintainer actually
use this?" skeptical check, and systems-thinker's R1 signal are three framings of
the same discipline.

**Implementation**: the `/ycc:skill-fitness` command enforces this via NH6's log.

---

## Unexpected Insights

### UI1 — The bundle needs a theory of _subtraction_, not just _addition_

Every persona's build list assumed skills are additive. None asked what makes a
skill retire-able. The systems-thinker came closest (LP #5 "rules about rules")
but framed it as governance for additions, not removals. The intersection of
systems-thinker's fragility-cliff and negative-space's inventory-gap framing
forces the question: **if the bundle is near a tipping point, the ratio of
additions to removals matters more than either in isolation.** `ycc` today has
no removal discipline; NH1 is the first proposal to address this at any persona.

### UI2 — The "empty hooks directory" is a complete Gawande-stack absence, not just a missing directory

Negative-space called the empty `hooks/` directory the single clearest
complementary absence (E10). Read through the analogist's Gawande lens, this is
deeper than a directory gap: **`ycc` ships the skill layer and the script layer
of the Gawande stack, but not the hook layer**. The bundle is systematically
one-third of the pattern. NH4 + NH6 (hook-shaped artifacts) begin closing this;
IA1 (Gawande default) prevents future additions from repeating the pattern.

### UI3 — Archaeology and futurism are not opposed; they are content and transport

Contradiction #2 in contradiction-mapping pitted archaeologist vs. futurist as
"MCP substrate vs. screen-scrape forever." The recombination reveals this is a
false opposition: the archaeologist's content (RANCID's cook-and-diff, MOP's
rollback-mandate, `router.db`'s flat-file simplicity) is **transport-agnostic**
and maps cleanly onto the futurist's 2027 MCP substrate. NH2 and NH5 are direct
instantiations of this synthesis. Claiming the archaeologist's content is "stuck
in the past" misses that only the _transport_ was 1997; the _discipline_ is
timeless.

### UI4 — The most leveraged new artifacts in the bundle are the ones that operate on the bundle itself

Three of the six novel hypotheses (NH1 sunset-review, NH3 skill-fitness, NH6
skill-telemetry) are **meta-artifacts** — they take `ycc` itself as their subject.
None of the 8 personas proposed a meta-artifact as their primary build candidate.
Yet these are the artifacts that (a) pay for themselves in descriptor-budget
savings, (b) enable downstream quality signals, and (c) resist the Booklore
scope-collapse pattern. The persona findings' implicit bias toward "downstream
subject" skills over "bundle-reflexive" skills is itself an unexpected insight;
the recombination exposes it.

### UI5 — "Hook" is the most underloaded word in the research corpus

Every persona endorsed hooks; no persona disaggregated what they meant. "PreToolUse
hook," "PostToolUse hook," "communication-checklist hook," "blast-radius hook,"
"cluster-context hook," "telemetry hook" are structurally different. Only when
you recombine personas do you see that `ycc`'s hooks directory needs to ship
**multiple hook classes** with a type discipline, not a single shape. This is why
NH4 (a PreToolUse hook firing a read-only agent) and NH6 (a PostToolUse hook
writing to a local log) are different — the Gawande taxonomy would call them
"communication checklist" and "audit trail" respectively, and they should not be
bundled as one hook.

---

## Key Insights

1. **The six novel hypotheses cluster into two groups**: three are **infra-domain
   artifacts that resolve persona contradictions** (NH2 RANCID-on-MCP, NH4 blast-
   radius-reasoner, NH5 MOP-as-policy), and three are **bundle-reflexive
   artifacts that manage authoring economics** (NH1 sunset, NH3 fitness, NH6
   telemetry). The second cluster is entirely absent from the persona findings
   individually — it emerges only when you look across them and ask "who owns the
   _authoring discipline_?"

2. **NH6 is load-bearing for NH1 and NH3.** Without local, append-only invocation
   telemetry, sunset and fitness are guesswork. If `ycc` ships any of the bundle-
   reflexive trio, NH6 must ship first. This is a rare dependency chain surfaced
   only by the recombination.

3. **The Gawande stack (IA1) is the single most important authoring convention
   that none of the personas codified as a shipped rule.** Analogist named it;
   bundle-author doesn't enforce it. Making it a default prompt in bundle-author
   is a ~10-line change that affects every future addition.

4. **Two of the six NHs (NH2, NH5) are H4-family skills from the crucible** (see
   `crucible-analysis.md`) expressed with sharper persona-combined framings than
   any individual persona provided. They do not replace H4; they are **specific
   instantiations of H4's workflow-shape class**, with the transport question
   (NH2's MCP-on-RANCID) and the discipline question (NH5's policy-lint-on-MOP)
   fully resolved.

5. **NH4 is the cleanest synthesis of the H3-vs-H4 crucible disagreement.** By
   packaging an agent that cannot act, it delivers H4's reasoning layer while
   inheriting H3's determinism posture (permissions > prompts). The crucible's
   discriminating question ("is skill-shape needed, or can scripts+hooks do it
   all?") is answered by: _"a read-only agent is skill-shape without the
   safety cost of a writable skill."_

6. **NH7 (coach-mode) is deliberately contingent and may be the first NH to
   retire if downstream audience is confirmed to be single-user.** This is
   structurally correct — the recombination produces it, but also produces its
   own falsifier via NH1's sunset discipline.

7. **Eight personas converged on ~5-6 artifacts; recombination produces 6 more
   at a different layer.** The convergent set is the **what** (infra workflow
   skills + hooks); the emergent set is the **how-to-sustain-the-what**. Neither
   alone is sufficient. The innovation finding is: **pair the converged set with
   at least NH1 + NH6 (telemetry + sunset) so the maintenance math of the whole
   expansion stays bounded.**

8. **The ratio of "safe, low-speculation" hypotheses to "genuinely speculative"
   hypotheses in this document is 6:1.** NH7 is the only one flagged
   [SPECULATIVE]. This is a deliberate calibration: per the Critical Instruction,
   every NH is tied to a documented failure mode. The speculative space (pure
   futurist scenarios: self-improving skills, regional MCP fragmentation, A2A
   agent cards in `ycc`) is visible in the futurist persona findings; this
   innovation document stays within the grounded space.

---

## Cross-Reference to Primary Recommendations

For the final build decision document, the NHs map to the crucible's hypotheses
as follows:

| NH                        | Primary crucible hypothesis                            | Relationship                                                      |
| ------------------------- | ------------------------------------------------------ | ----------------------------------------------------------------- |
| NH1 sunset-review         | orthogonal to all                                      | Makes H4 and H7 safer by bounding growth                          |
| NH2 archive-as-service    | H4                                                     | Specific instantiation of `network-change-review` workflow class  |
| NH3 skill-fitness         | orthogonal to all                                      | Governance layer under any hypothesis                             |
| NH4 blast-radius-reasoner | H4                                                     | Resolves H3-vs-H4 by packaging reasoning without write permission |
| NH5 MOP-as-policy         | H4                                                     | Specific instantiation of archaeologist's P0 MOP revival          |
| NH6 skill-telemetry       | prerequisite under any                                 | Enables NH1, NH3, NH4                                             |
| NH7 maintainer-mode       | H4 (if downstream audience) / deferred (if owner-only) | Contingent on Contradiction #8                                    |

Recommended minimum ship set for H4 + anti-fragility: **NH6 + NH1 + NH4 + NH5.**
This combines one bundle-reflexive trio member + one enabling primitive + two H4
workflow skills. Total source artifacts added: ≤5. Total generated (×4 targets):
≤20. Well under the 70-90 tipping point (E17).

---

## Methodology Notes

- **Combinatorial process**: for each of the five suggested persona combinations
  in the task brief, I generated candidate hypotheses and pressure-tested each
  against "does any individual persona already propose this?" If yes → cut. If
  no → traced to specific evidence items in the crucible's evidence catalog
  (E1-E30) and the contradiction-mapping to verify it addresses a documented
  failure mode.
- **Failure-mode grounding**: every NH cites at least one evidence item from
  `crucible-analysis.md`'s E1-E30 list and/or a specific contradiction from
  `contradiction-mapping.md`. No NH is ungrounded.
- **Falsifiability**: every NH has a testable prediction with a specified time
  window and a clear refutation condition. This is per the Critical Instruction
  and also per Heuer's analysis-of-competing-hypotheses discipline (disconfirmation
  > confirmation).
- **Speculation labeling**: only NH7 is explicitly [SPECULATIVE], and its
  speculation is scoped to "if there is a downstream audience." Other NHs
  contain no speculation beyond the evidence base.
- **Limits**: this synthesis did not generate new evidence via searches. It is
  bounded by the 8 persona findings, the crucible analysis, and the contradiction
  mapping. Where the personas lack data (e.g., owner's monthly workflow
  weighting), the NHs that depend on that data (NH7) are explicitly contingent.

---

_End of innovation document._
