# Tension Mapping — ycc Ecosystem Enhancements

**Role**: Tension Mapper (Asymmetric Research Squad, crucible phase)
**Date**: 2026-04-20
**Inputs**: 8 persona findings + `crucible-analysis.md` + `contradiction-mapping.md` + `verification-log.md`
**Mandate**: Identify **irreducible trade-offs** — the hard choices the maintainer must actually make. Do not re-map the contradictions already resolved by the contradiction-mapper and ACH analyst.

---

## Executive Summary

The prior synthesis stages did their job: the contradiction-mapper showed that ~80% of cross-persona conflict is vocabulary drift ("skill-alone" vs. "skill + script + hook bundle") or dosage ("ship 3" vs. "ship 15") disagreement around an agreed direction (hooks + workflow-shape > vendor-matrix). The ACH analyst decisively eliminated H1 (vendor matrix) and consolidated the surviving strategies into H3 (hooks only), H4 (workflow + hooks), and H7 (hybrid). **Most of what looked like disagreement evaporated under analysis.**

What remains are the tensions that _cannot_ be dissolved by better definitions or more evidence. They sit at the seams where **two load-bearing values pull in opposite directions at the same time**, and no amount of research will relax the pull. The maintainer must pick.

The seven maximum-tension points I identify:

1. **Safety-by-gate vs. Agency-by-speed** — every hook that prevents a wrong-cluster `kubectl delete` also slows down the feedback loop that built auto-approve trust from 20% → 40% in the first place. Safety and trust-velocity are in direct opposition.
2. **Source-of-truth singularity vs. 4×-target reality** — the "one ycc" consolidation (2.0.0) is philosophically right and maintainance-mathematically wrong for hooks, which have radically different semantics across Claude / Cursor / Codex / opencode.
3. **Workflow-shape (vendor-agnostic) vs. Hallucination-floor (vendor-specific RAG)** — workflow-shaped skills have 5× lower maintenance cost but inherit the 85% LLM-alone ceiling on vendor CLIs; closing that ceiling requires exactly the vendor-specific RAG corpus that workflow-shape deliberately refuses.
4. **Personal toolkit vs. Shipped ecosystem** — every design choice that optimizes for the maintainer's own daily use (thin docs, implicit context, opinionated defaults) makes the bundle worse for downstream users; every choice that optimizes for downstream users burns time the maintainer doesn't have and doesn't observably recoup.
5. **Substrate-neutrality vs. Substrate-dependence** — ycc cannot both "tolerate either Ansible-retreat or MCP-maturity" (Contradiction #6 deferral) _and_ ship workflow skills that produce specific, useful outputs today. Deferring the substrate bet is itself a bet against all substrates.
6. **Keystone discipline vs. Opportunity cost of restraint** — each artifact the maintainer does _not_ ship (following Gawande's keystone filter) is a specific documented failure mode that continues happening in production. "Restraint is right at scale" and "each individual case is defensible" are both true; something has to lose.
7. **Meta-skill leverage vs. Unproven-at-scale** — the systems-thinker's LP #6 intervention (router/meta-skill) has the highest theoretical leverage and the weakest empirical evidence. Adopting it is a bet on a framework nobody has validated at 50+ skill bundle sizes; rejecting it is a bet that leaf-skill density is survivable.

These tensions share a common shape: **they are not errors to correct. They are budget constraints to allocate.** The maintainer's answer is not "find the truth" but "choose which value to starve when both cannot be fed."

The single most load-bearing observation: **five of the seven tensions resolve only if the maintainer self-reports their actual monthly workflow weighting (Contradiction #8).** Without that input, the research is making recommendations to a persona composite, not to an individual. The ceiling of external analysis has been reached.

---

## Maximum Disagreement Points

### MDP-1 — Safety-by-Gate vs. Agency-by-Speed

**Type**: Value / Trade-off (irreducible)

**Side A — Safety-by-gate** (contrarian, negative-space, analogist, archaeologist):
Every hook, every PreToolUse check, every confirmation prompt reduces the probability of the Kiro-class incident (E9). The entire ecosystem has converged on this: Juniper's `block.cmd` regex, Palo Alto's `PANOS_READONLY`, Claude Code's own MCP safety-hooks skill. Safety is deterministic; probabilistic safety is "worse than useless" (contrarian).

**Side B — Agency-by-speed** (futurist, implicit in systems-thinker's R1 loop):
Claude Code's auto-approve rate rises from ~20% (<50 sessions) to 40%+ (750+ sessions) — the trust curve is _earned by velocity_. Every gate that interrupts the loop slows trust calibration and retards the very feedback mechanism (E26, E27) that makes the maintainer's daily use produce a better bundle. A skill the maintainer has to stop-and-confirm for 10x per hour becomes a skill they don't reach for.

**Severity**: High. Directly shapes how hooks are designed.

**Resolvability**: Low. The tension is structural — every gate trades latency for protection. Tuning thresholds helps but doesn't eliminate the trade-off.

**Insight**: The contrarian's "hooks are safety; skills are confabulation" framing implicitly assumes the hook-cost is zero. It is not. A hook-heavy design violates the R1 reinforcing loop (author uses → feedback → improves) by shifting the maintainer's own posture from _flow_ to _gatekeeper_. The archaeologist's `copy run start` guard prevented disasters and was also the reason junior engineers copy-pasted around it. Any `ycc:netops-blast-radius-guard` that fires on every `terraform apply` will be disabled within 60 days by the person it was designed to protect. Safety that defeats the feedback loop that produced it is self-canceling.

**Implementation consequence**: Hooks must be **rare, high-precision, and proportional to blast-radius**. The E30 consensus ("every safety plugin is a hook") is right about the _shape_ and silent about the _frequency_. A `ycc/hooks/` directory shipping 8 PreToolUse hooks firing on common commands is a different artifact than one shipping 2 PreToolUse hooks firing only on `*-prod-*` context matches — even though both count as "hooks." The maintainer must pick a firing rate, and the surviving hypotheses (H3, H4, H7) all silently assume the low-firing-rate variant without saying so.

---

### MDP-2 — Source-of-Truth Singularity vs. 4×-Target Reality

**Type**: Conceptual / Architectural (semi-irreducible)

**Side A — Source-of-truth singularity** (repo policy, `ycc` 2.0.0 consolidation):
The plugin collapsed from 9 plugins to 1 (`ycc`) deliberately. Every skill / command / agent has a single canonical form under `ycc/`, generated into 4 compat bundles. This is load-bearing for maintainability: no hand-edits to generated files, one validation pipeline, one release.

**Side B — 4×-target reality** (systems-thinker E29, contrarian):
"Every hook is 4 hooks" because Cursor, Codex, and opencode each have different hook semantics. Cursor doesn't consume `.md` commands natively. Codex has no slash-command layer. opencode has distinct hook semantics. The "single source of truth" abstraction **breaks at the hook layer** in a way it does not break at the skill/agent layer. For skills, the `ycc/skills/{name}/SKILL.md` format maps cleanly to all 4 targets via mechanical generation. For hooks, the _semantics_ differ across targets, not just the format.

**Severity**: High. Determines whether H3 / H4 / H7 are ship-able within the current architecture or require an architectural change first.

**Resolvability**: Partial. Workable via per-target hook generators (analogous to the existing per-target skill/agent generators), but at real cost: the hook generator becomes the most complex script in the repo, the validators multiply, and the "one ycc" promise partially fails for the one artifact class all personas identify as highest-value (E10, E30).

**Insight**: The consolidation-to-`ycc` decision was correct for the artifacts that existed in 2.0.0 (skills, agents, commands — all of which are _prose with frontmatter_ at the core, trivially transformable). It was silent on hooks because hooks were not a net-new addition at consolidation time. The highest-leverage expansion ahead (hooks) is the one artifact class that stresses the consolidation architecture. **The repo's own structural decision predates the feature it most needs.** The maintainer must either (a) extend the 4× generator pipeline to handle hook-semantic differences — a non-trivial refactor — or (b) ship hooks Claude-only and break the cross-target parity promise on its highest-value artifact — a real admission that the consolidation was incomplete. There is no "do neither" option that also lets hooks ship.

---

### MDP-3 — Workflow-Shape vs. Hallucination-Floor

**Type**: Trade-off (irreducible at current model capability)

**Side A — Workflow-shape** (historian F3, analogist, futurist, journalist):
Vendor-agnostic workflow skills (`network-change-review`, `mop`, `pre-post-check`) have ~5× lower maintenance cost, escape the vendor-rebrand risk (E21), fill the empty cross-vendor niche (E24), and match the convergent research spine (E11).

**Side B — Hallucination-floor** (contrarian E3, negative-space):
LLMs alone top out at ~85% syntax correctness on vendor CLIs (IRAG arXiv:2501.08760). Reaching the 97.74% ceiling requires RAG over vendor manuals (7,300+ pages for Huawei NE40E). A vendor-agnostic workflow skill cannot ship the vendor-specific RAG corpus — that is definitionally what "vendor-agnostic" rejects. When `network-change-review` delegates the "parse this Cisco config diff" step to the underlying LLM, it inherits the 85% ceiling silently and masks it behind a workflow-shaped UI.

**Severity**: High. Determines whether workflow skills are actually safer than vendor skills or just _feel_ safer.

**Resolvability**: Medium. Workflow skills can route to vendor MCPs (journalist's position) when available, which shifts the hallucination problem to the vendor MCP side where RAG is already happening. But this only works where MCPs exist — exactly the brownfield/legacy territory the archaeologist flags (20-40% CLI-only in 2026) has no MCP to route to, and workflow skills silently revert to LLM-alone mode.

**Insight**: The cross-persona convergence on "workflow-shape > vendor-shape" (strongest signal in the research per contradiction-mapper) contains a hidden premise: that someone _else_ is carrying the vendor-specificity burden. In greenfield/MCP-available cases, vendor MCPs carry it (true). In brownfield/CLI-only cases, nothing carries it — the workflow skill runs against raw LLM output. The maintainer is choosing not _between_ workflow and vendor, but _between_ "accept the hallucination ceiling for my 20-40% brownfield work" and "pay the vendor-matrix maintenance tax to close that ceiling." The research as a whole has not faced this choice directly because the convergence looked too strong to interrogate.

**Implementation consequence**: H4's `network-change-review` should either (a) explicitly refuse to run against non-MCP substrates (fail closed), (b) ship with a pitfalls layer (H6) that warns users at the exact boundaries where LLM-alone mode kicks in, or (c) accept the 85% ceiling as an honest limitation of the skill. **The one option that is not defensible is silent silent reversion** — and that is what a naive H4 implementation does.

---

### MDP-4 — Personal Toolkit vs. Shipped Ecosystem

**Type**: Stakeholder / Purpose (partially resolvable by owner declaration)

**Side A — Personal toolkit**:
If `ycc` is primarily the maintainer's personal tool (systems-thinker R2 not dominant), then every design choice should optimize for their daily flow: implicit context ("I know what I meant"), thin docs (I wrote it), opinionated defaults (I know how I work), no user-facing compatibility guarantees.

**Side B — Shipped ecosystem**:
If `ycc` has a downstream audience (Claude marketplace, Cursor/Codex/opencode users), then every design choice must assume a reader who is _not_ the maintainer: explicit context, thorough docs, conservative defaults, compatibility guarantees, issue triage, PR review cycles. The 4× compat bundle infrastructure only makes sense under this framing.

**Severity**: Very High. Every other design decision pivots on this.

**Resolvability**: High, but only via direct owner input (Contradiction #8 irreducible unknown per contradiction-mapper).

**Insight**: The most revealing observation is that **the repo is currently structured as if Side B is true** (4× compat bundles, validators, CONTRIBUTING.md, bundle-author + compatibility-audit workflows, bundle-release skill) **but the persona analysis implicitly assumes Side A** (the maintainer will catch drift through R1 loop, "3-times-in-60-days" personal-use test is sufficient signal, unknown user mix is a constraint not an input). **These two framings have been running in parallel through the research and never collided.** The maintenance tax of Side B is real and sunk. The value extraction of Side B is uncertain and unmeasured.

If Side A is the honest truth, then the 4× compat pipeline is over-engineered and every hour spent on it is waste. If Side B is the honest truth, then the persona findings' reliance on "owner uses 3× / 60 days" tests is wrong: the test should be "does this help a downstream user who is not the owner?" — a harder bar that several of the surviving build-list items fail. **The current posture is the worst of both worlds: paying Side B's cost while making Side A's design decisions.**

**Implementation consequence**: If the maintainer declares Side A, several simplifying moves unlock: skip the 4× compat for low-value artifacts, use personal-use tests, tolerate opinionated defaults. If Side B, the build list shrinks further (must pass downstream-user test, not owner-use test) and the compat pipeline investment is justified. **The posture-of-the-repo must align with the honest-use pattern, or both suffer.**

---

### MDP-5 — Substrate-Neutrality vs. Substrate-Dependence

**Type**: Temporal / Architectural (irreducible by research; resolves in time)

**Side A — Substrate-neutrality**:
"Architect for either outcome" (contradiction-mapper's Resolution Priority 5, recommendation for Contradictions #2 and #6). Don't bet on Ansible-network-collections surviving. Don't bet on vendor MCPs reaching saturation. Build workflow skills that can sit over _any_ substrate.

**Side B — Substrate-dependence**:
To produce specific, useful output, any workflow skill must _call something_: an Ansible module, a vendor MCP, a Netmiko session, a Terraform provider. Every call commits the skill to that substrate's continued existence. "Substrate-neutral" at the skill level becomes "substrate-neutral through a cascade of if/else branches" at the implementation level — an anti-pattern (analogist's pre-2023.2 Big Data Tools mega-skill warning).

**Severity**: Medium-High. Shapes whether ycc's workflow skills are portable over 2026-2028 or ossify against a specific substrate mix.

**Resolvability**: Low in the near term. The research explicitly flagged Ansible-network-abandoning (Contradiction #6) and vendor-MCP-maturity (Contradiction #2) as irreducible unknowns that resolve only with time. But _designing for both_ at the code level is its own problem: either (a) the skill has adapter logic that tracks every substrate shift (expensive, per-vendor-per-year), or (b) the skill delegates to _one_ substrate and rewrites when that substrate breaks (cheap per year, expensive when it breaks).

**Insight**: The contradiction-mapper's "architect for either outcome rather than bet on one" is a _recommendation_ at the meta-level that doesn't translate cleanly to the artifact level. A real `network-change-review` skill in 2026 has to pick: does it shell out to `ansible-playbook`, to a vendor MCP, to Netmiko directly, to `terraform plan` for IaC-backed networks? Each choice commits. **The persona-level "be neutral" resolution is a non-commitment that the implementation cannot honor.** The systems-thinker's R2 stability loop depends on substrate durability, which depends on exactly the bets the contradiction-mapper deferred.

**Implementation consequence**: The maintainer must accept that any workflow skill shipped today will be **single-substrate-dominant** (probably MCP-preferred with CLI fallback) and will need rewriting in 2-3 years if the dominant substrate shifts. The substrate-neutral framing is a design principle; the code is a bet. Pretending otherwise burns time in adapter abstractions that never pay off.

---

### MDP-6 — Keystone Discipline vs. Opportunity Cost of Restraint

**Type**: Value (irreducible — zero-sum between restraint and gap-closure)

**Side A — Keystone discipline** (systems-thinker, analogist, contrarian):
The fragility-cliff frame (E17) plus the keystone filter (analogist: "not body count, not wall-to-wall coverage") dictates ~4-6 artifacts max. Every artifact the maintainer does _not_ ship is the right decision at scale, regardless of its individual merit.

**Side B — Opportunity cost of restraint** (archaeologist, negative-space):
Each unbuilt artifact corresponds to a specific documented failure mode that continues happening. MOP-without-rollback incidents don't stop because the maintainer chose restraint. The 15-item punch list represents 15 real gaps; shipping 4 leaves 11 gaps open. "Restraint is right at scale" and "each gap is real" are both true — and when they collide, something has to be starved.

**Severity**: High. This is the translation of the fragility-cliff frame into individual case-by-case decisions, and the cases feel different from the frame.

**Resolvability**: Not by research. Only by the maintainer accepting that the restraint _has cost_, the cost is real gaps staying unfilled, and that the scale-level argument overrides the case-level argument _by design_.

**Insight**: The ACH analyst cleanly eliminated H1 (vendor matrix) on scale grounds. But H4 (4-6 artifacts) vs. H7 (3 artifacts) vs. H2 (zero artifacts) is **not cleanly decidable** — each additional artifact has a case-level defense the ACH scoring captures weakly. The contradiction-mapper called this "dosage disagreement" (Insight 2) and moved on; the dosage disagreement _is the tension_ and moving on doesn't resolve it.

Concretely: shipping H4's `evidence-bundle` artifact fills a real compliance gap (negative-space) and adds one more leaf skill the maintainer must keep working across 4 targets (E23, E29). Shipping H7 without it means the compliance gap stays open indefinitely. There is no version of the research that says "the evidence-bundle gap does not matter" — it says "the aggregate cost of filling all gaps exceeds the aggregate benefit." The aggregate statement is correct; the per-case pain remains.

**Implementation consequence**: The maintainer should accept that shipping H4 or H7 means **deliberately leaving documented gaps unfilled**. This is the cost of keystone discipline. Pretending the gaps are not real, or that they will be filled "later," is the failure mode the archaeologist warns against (forgotten wisdom). The honest posture: "these gaps exist, I am choosing to leave them open because the aggregate cost exceeds the aggregate benefit, and I will revisit in 6 months if the shipped artifacts prove their keystone status."

---

### MDP-7 — Meta-Skill Leverage vs. Unproven-at-Scale

**Type**: Trade-off / Evidentiary (partially resolvable by experiment)

**Side A — Meta-skill leverage** (systems-thinker LP #6, analogist):
A router meta-skill (`ycc:infra-route`) that dispatches to existing `ycc:plan` / `ycc:code-review` / `ycc:git-workflow` has sub-linear descriptor cost. One new descriptor unlocks N latent workflows without N new descriptors. This is the highest-theoretical-leverage move in the entire research.

**Side B — Unproven-at-scale** (systems-thinker's own caveat, contradiction-mapper #7):
"Meta-skill effectiveness unproven at this scale. 'Skills-of-skills' is a sound theory but I have not surveyed concrete evidence of routers outperforming leaf skills at 50+ skill bundle sizes." The most leveraged move is also the least evidence-backed.

**Severity**: Medium. A wrong bet here wastes one skill slot; a right bet reshapes the bundle's scaling curve.

**Resolvability**: Partial. Only by building and measuring. The research cannot close this — it must be closed by live experiment.

**Insight**: This tension is different from the others: it's not "two values pulling opposite" but "the highest-reward option is the highest-uncertainty option." The systems-thinker is simultaneously the most-bullish on meta-skills as a principle and the most-honest about lacking empirical support. **Every other persona quietly ignored the meta-skill option** (H5 survived in the ACH analysis only as an internal design principle, not a primary strategy).

The silent agreement across personas is: "we don't know if meta-skills work at this scale, and we're going to recommend leaf-skill additions because we know those work." This is correct risk-aversion and also leaves the systems-thinker's highest-leverage intervention unexplored.

**Implementation consequence**: The honest path is an explicit experiment: ship H4/H7 _and_ one meta-skill (`ycc:infra-route` or similar), measure descriptor invocation rates across 30-60 days, and retire whichever performs worse. This is more maintenance upfront, less in 12 months if the meta-skill wins. The research cannot pick for the maintainer — the only way to resolve MDP-7 is to try it.

---

## Stakeholder Tensions

Who wants opposite things? The persona findings identified a limited but important set of stakeholder conflicts. Most are already resolved in the contradiction-mapping; what remains are the ones that don't dissolve.

### Maintainer (one person) vs. Downstream users (uncertain audience)

See MDP-4. The deepest stakeholder tension — the maintainer wants a personal tool that fits their flow; a downstream user (if any) wants a documented, stable, unopinionated artifact. The repo is currently investing in the latter and the persona analysis is implicitly built on the former. **Unresolved.**

### Greenfield users vs. Brownfield users

- **Greenfield** (SaaS, cloud-native, MCP-available): wants workflow skills that compose over vendor MCPs. Opposed to any Expect/Netmiko/legacy helpers.
- **Brownfield** (telco, OT, legacy enterprise, air-gapped): wants exactly the Expect/Netmiko/CLI helpers the greenfield side rejects. Cannot consume cloud-inference skills.
- **Maintainer's position in this mix**: unknown. If 80% greenfield, the brownfield features are dead weight. If 20% greenfield, skipping them misses the 80%.

The futurist and archaeologist are proxies for these two audiences. Their disagreement (MDP-5 indirectly) is a stakeholder tension wearing a temporal disguise.

### Vendors shipping MCPs vs. Ecosystem shipping wrappers

Vendor MCPs (Palo Alto Cortex, Juniper Junos MCP, Cisco Network MCP) want to _be_ the AI interface to their platform. A ycc wrapper competes with them for descriptor budget and mindshare. But vendors do not ship cross-vendor workflow synthesis — they have no incentive to (journalist). The empty-niche argument (E24) is downstream of this tension: vendors want per-vendor, ecosystem wants cross-vendor, and neither fully fills the gap.

**Stable resolution**: ycc ships orchestration-above-MCP, never wrapper-around-MCP. But this requires vendor MCPs to exist (Contradiction #2 deferred → becomes MDP-5 at artifact level).

### Auto-approve-fast users vs. Manual-review-safe users

Claude Code auto-approve rates (E26) rise with trust. Hooks reduce auto-approve because they _require_ manual approval. Users who worked for months to reach 40%+ auto-approve do not want hooks dragging them back to 20%. Users who fear Kiro-class incidents want more hooks, not fewer.

**These are not two user groups — they are two states of the same user over time.** Early-career trust: wants hooks. Mature-trust: wants fewer hooks. A single `ycc/hooks/` directory cannot be both without graduated thresholds (MDP-1 implementation consequence).

---

## Value Tensions

Specific values that cannot be co-maximized.

### Speed vs. Safety

See MDP-1. Every gate trades latency for protection. Fully resolvable only by declaring a priority ordering — and the research is silent on which priority the maintainer should hold. Both the contrarian and the futurist assume their priority ordering is the right one.

### Coverage vs. Focus

See MDP-6. Every artifact filled means one less gap; every artifact skipped means one less maintenance burden. The fragility-cliff frame forces focus; the documented-failure-mode frame forces coverage. Irreducible.

### Completeness vs. Maintainability

The `ycc` bundle's consolidation philosophy optimizes for completeness-within-one-plugin (everything accessible via `ycc:` prefix). Maintainability argues for shipping fewer artifacts. Completeness within a small artifact set is possible only if each artifact is genuinely keystone.

**Novel observation**: the `ycc` bundle has already _won_ the completeness argument at the namespace level (one `ycc:` prefix covers everything). This makes it _harder_ to resist adding to that namespace, because each addition benefits from existing discoverability. The consolidation's success creates expansion pressure.

### Consistency vs. Target-native-ness

The 4× compat pipeline forces consistency across Claude / Cursor / Codex / opencode. But each target has native idioms (Cursor's rule format, Codex's TOML agents, opencode's distinct hook semantics). A "consistent" artifact is non-idiomatic in at least 3 of 4 targets. An "idiomatic" artifact requires per-target customization that defeats the 4× generator pipeline.

The current posture is consistency-first, which produces artifacts that read as slightly-foreign in Cursor/Codex/opencode. The tension surfaces at hook semantics (MDP-2) but exists broadly.

### Determinism vs. Judgment

Contrarian: skills are probabilistic; only hooks deliver deterministic safety. Archaeologist: MOP authoring, pre/post-check reasoning, config-drift cooking all require _judgment_ — which is exactly what hooks cannot provide and skills are shaped for.

Contradiction-mapper #4 resolved this definitionally (skill + script + hook bundle). But the deeper tension survives: _when judgment and determinism conflict in a single workflow, which wins?_ A skill that reasons about blast-radius but ships a hook that blocks "production"-named contexts will block exactly the cases where judgment would have allowed the change. The determinism overrides the judgment by design. The archaeologist's judgment layer is subordinated to the contrarian's determinism layer whenever they disagree. **The analogist's three-layer stack has an implicit priority ordering that was never stated.**

---

## Trade-off Tensions

What cannot be optimized simultaneously.

### Descriptor budget vs. Gap closure

Every new skill descriptor adds ~1K-5K tokens to the descriptor-prompt floor. The 70-90 skill tipping point (E17) is a context-window constraint. Every gap filled is a descriptor added. **Gap closure buys descriptor budget directly.**

The irreducible trade-off: 4-6 new artifacts (H4) pushes the descriptor floor closer to the cliff; zero new artifacts (H2) leaves gaps open; the intermediate choices are linearly priced. There is no "free" addition.

### Hook precision vs. Hook coverage

A hook that fires on "any `kubectl delete`" catches too many cases; one that fires only on `kubectl delete` against `*-prod-*` contexts catches exactly the Kiro-class cases but misses the `prod-us-east-1` named cluster that doesn't match the regex. Precision and coverage are opposed; every hook's firing rule is a trade-off point.

The current persona consensus is "high-precision, blast-radius-proportional hooks." But precision requires knowing the user's naming conventions — which the bundle doesn't know. Either the hooks ship with configurable regex (user maintenance tax) or fixed regex (false-negative rate on users who name things differently).

### Adoption velocity vs. Governance rigor

Hooks introduce attack surface (Contradiction #10). The systems-thinker's "48-hour cool-off for hook PRs" is the right governance. But cool-off slows adoption — any user-submitted hook takes 48+ hours to land. At ecosystem scale, this chills contribution.

For a single-maintainer bundle, this trade-off is near-zero (no contributions expected anyway). But it's also near-zero _because_ the bundle isn't attracting contributions, which loops back to MDP-4.

### 4×-target reach vs. Target-idiom quality

See "Consistency vs. Target-native-ness" above and MDP-2.

### LLM-era speed vs. Legacy-discipline thoroughness

The archaeologist's disciplines (cook-and-diff, flat-file inventory, MOP, pre/post-check) are slow and thorough. The LLM era expects fast iteration. A `ycc:mop` skill that forces the user to author a full Method of Procedure with rollback commands before deploy is correct by archaeological standards and friction-heavy by LLM-era standards.

Users who adopted Claude Code for speed will route around MOPs the first time they can; users who adopted it for safety will demand them. Same tool, two users, opposite reactions.

---

## Temporal Tensions

What conflicts across timeframes?

### Ship-now (2026) vs. Architect-for-MCP-maturity (2028)

The futurist's 2027-2028 MCP saturation forecast (E12, 25% of initial network configs by GenAI by 2027) is strong directionally and uncertain in timing. Shipping workflow skills now that route to MCPs-when-available works for the 2027-2028 future and fails in the 2026 brownfield present (MDP-3, MDP-5).

The irreducible tension: a skill optimized for 2028 substrate looks thin in 2026; a skill optimized for 2026 substrate becomes technical debt in 2028. No version works well across both years. **The maintainer must pick a year.**

### Build-before-hype-cycle vs. Ride-hype-cycle

The Ivan Pepelnjak critique (E13, "AI is the new SDN") warns that every hype cycle burns maintainer attention on artifacts that become obsolete when the cycle shifts. Building hooks and workflow skills in 2026 might be right on merit and wrong on timing (same-as-SDN artifacts died on timing, not merit).

Alternatively: not building in 2026 means missing the converged NL→IR→validate→deploy→verify spine (E11) that four independent research tracks identified. Right-timing is as irreducible as right-artifact.

### Ansible-substrate-persistence vs. Ansible-substrate-retreat

Contradiction #6 is a live uncertainty. A workflow skill that assumes Ansible-network-collections is a safe substrate makes a bet on the 2015-2022 pattern continuing. A workflow skill that avoids Ansible makes a bet on the 2024-2026 retreat continuing. The research cannot pick.

### Early-career trust vs. Mature trust

See "Auto-approve-fast vs. Manual-review-safe" in Stakeholder Tensions. The same user wants different hooks at different career stages. The artifact must pick a target stage.

### Skill descriptor persistence vs. Model-version-cycling

Claude Opus 4.6 → 4.7 → 5.x will likely absorb larger descriptor budgets (futurist hopes). Skills that make sense at 4.7's context window may be redundant at 5.x's. But skills live longer than individual model versions. **Building skills for the current model's capabilities is a bet that those capabilities are the durable shape.**

---

## Conceptual Tensions

Fundamental concepts that contradict.

### "Skill" as prompt vs. "Skill" as compound artifact

Contradiction-mapper #4 flagged this as vocabulary drift and moved on. But the _conceptual_ residue remains: the Claude Code architecture treats skills as self-contained units with optional scripts/references, while the analogist's Gawande stack treats skills as one leaf of a three-leaf compound. When the ycc bundle ships a "skill," which conceptualization is the user consuming?

The current `ycc/skills/{name}/` directory structure (SKILL.md + references/ + scripts/) supports the compound reading. But users invoke skills via `ycc:{name}` which is a single namespace identifier (prompt reading). The architecture is dual; the user experience picks one. **The conceptual tension manifests at the invocation boundary.**

### "Safety" as blocked-action vs. "Safety" as informed-action

The Kiro-model-of-safety (block the delete) is different from the Gawande-model (surface the information, let the operator decide). Hooks can do either — a hook that blocks `kubectl delete` against prod is model-1; a hook that surfaces "this affects 23 services, blast radius high, proceed?" and allows Y/N is model-2.

The contrarian implicitly prefers model-1 (deterministic block); the analogist implicitly prefers model-2 (surface-then-decide). Both call it "safety." The implementations are radically different. The maintainer must pick a model per hook.

### "Workflow" as linear process vs. "Workflow" as reactive loop

Futurist's NL→IR→validate→plan→confirm→deploy→verify (E11) is linear. Archaeological MOP + pre/post-check + cook-and-diff is loop-shaped (watch → detect → diff → decide → commit → verify → re-watch). Both call themselves workflow.

A `ycc:network-change-review` skill shaped as a linear pipeline misses the ongoing drift-detection reality. A skill shaped as a reactive loop doesn't fit the "review this one change" use case. **Workflow is not one shape; the research collapsed it into one label.**

### "Vendor-agnostic" as architectural ideal vs. "Vendor-agnostic" as operational fiction

Every vendor-agnostic workflow skill, on execution, runs against a specific vendor's artifact. The architecture can be agnostic; the execution cannot. Calling a skill "vendor-agnostic" describes the intent, not the runtime. **Agnosticism is a property of the maintainer's worldview, not of the code.**

### "Keystone" as value descriptor vs. "Keystone" as testable property

The analogist's keystone filter ("not body count, not wall-to-wall coverage") is operationally seductive but untestable. Whether `ycc:mop` is a keystone skill is a judgment the maintainer makes. The research cannot test it. If every maintainer calls their own favorite artifacts "keystone," the filter loses discriminating power. **The filter is a heuristic that presumes the person applying it is calibrated; the research doesn't check the calibration.**

---

## Key Insights

1. **Five of seven MDPs resolve only via owner self-report** (MDP-1 firing rate, MDP-4 purpose, MDP-5 substrate bet, MDP-6 gap-acceptance, MDP-7 experiment willingness). The research has hit its ceiling on these and further analysis is waste. The maintainer must answer directly or the answers are guesses.

2. **The consolidation-to-`ycc` decision predates its own hardest test** (MDP-2). Hooks stress the source-of-truth singularity in a way skills/agents/commands do not. The 2.0.0 consolidation is correct but incomplete — it made a promise (one source of truth, mechanically generated to 4 targets) that does not extend to the artifact class the research identifies as highest-value.

3. **Every persona silently assumed their priority ordering was correct.** Contrarian assumed safety > velocity. Futurist assumed velocity → trust → velocity. Archaeologist assumed discipline > speed. None of the personas surfaced this and none of the cross-persona synthesis stages did either. **The research is a set of coherent worldviews in silent disagreement about values, not a convergence on a single answer.**

4. **Convergence is a signal, not a verdict.** Six of eight personas converged on "workflow-shape > vendor-shape" (contradiction-mapper Insight 1). This looked like the strongest research signal. MDP-3 shows the convergence contains a hidden premise (someone else carries vendor-specificity via MCPs) that fails in brownfield cases. **Strong convergence across personas with aligned framing is not the same as strong convergence on the full problem.**

5. **Determinism wins ties with judgment by design.** When a `ycc:mop` skill reasons toward "proceed" and a `copy run start` hook says "block," the hook fires. The analogist's three-layer stack (skill + script + hook) has an implicit priority ordering the research never stated: hook > script > skill in conflict cases. This is correct for safety but constrains the judgment layer's value to "when the hook has nothing to say." The archaeologist's judgment is secondary to the contrarian's determinism, always.

6. **The maintainer is both the quality filter and the resource constraint.** R1 reinforcing loop (maintainer uses → feedback → improves) depends on the maintainer's daily flow. Fragility-cliff frame bounds the maintainer's attention. Personal-toolkit vs. shipped-ecosystem tension (MDP-4) is the maintainer's identity question. **The maintainer is not a stakeholder in this research — they are the variable every other stakeholder is a function of.** The contradiction-mapper's Irreducible #1 ("monthly weighting") is structurally the entire problem restated.

7. **Most "irreducible" tensions are irreducible-to-research, not irreducible-in-principle.** MDP-7 (meta-skill leverage) resolves by experiment. MDP-5 (substrate bet) resolves in 2-3 years. MDP-1 (firing rate) resolves by tuning. Only MDP-4 (personal vs. shipped) is philosophically unresolvable — every other tension is a _bet the maintainer must make with incomplete information_. **The research produced a decision matrix, not a truth.**

8. **The honest next step is a decision document, not more research.** Each MDP has a resolution mechanism (self-report, declaration, experiment, bet). None require further persona analysis. The research corpus is complete; the maintainer's decision is pending. Adding a ninth persona would add text without reducing tension.

9. **The single most neglected tension is hook firing rate** (MDP-1 implementation consequence). Every surviving hypothesis (H3, H4, H7) assumes hooks are high-precision / low-firing-rate without saying so. If the maintainer ships 8 hooks at high firing rates, the result is a user-hostile bundle whose hooks get disabled within 60 days. The persona-level consensus on "hooks are good" is silent on "hooks at what rate."

10. **The `ycc` bundle's density is itself a tension amplifier.** At 45 skills, each addition looks individually small. At 140 source artifacts × 4 targets = 560 generated files, each addition is structurally large. The maintainer sees the individual-add cost; the system bears the aggregate-add cost. **The bundle has outgrown the maintainer's intuitive cost model** (E20 bias #5 made explicit). Future decisions need an aggregate-cost tool, not individual-case intuition.

---

## Methodology Notes

- **Tension identification**: started from the 11 contradictions in contradiction-mapping.md and the 7 hypotheses in crucible-analysis.md. Filtered out tensions resolved at the vocabulary / dosage / base-rate level. Retained tensions that would survive perfect definitions and infinite evidence.
- **Distinguishing tension from contradiction**: a contradiction is two claims that cannot both be true; a tension is two values that cannot both be maximized. Contradictions dissolve under analysis; tensions require allocation. This mapping is explicitly about the latter.
- **Seven MDPs, not more**: I resisted the pull to enumerate every minor trade-off. The seven MDPs are the trade-offs where the maintainer's decision will _change the ship plan_ — not the trade-offs where the plan is invariant.
- **Separation of owner-resolvable vs. experiment-resolvable vs. permanently-irreducible**: surfaced in Key Insight #7. This is a more useful taxonomy than "how severe is the tension" because it maps to a specific next step.
- **Limits**: the research cannot measure the maintainer's monthly workflow weighting (MDP-4 core input), the actual firing rate the maintainer will tolerate (MDP-1 implementation), or the real 4×-target cost of hook generation (MDP-2 cost). These are operational measurements requiring live data from the owner.

---

## Confidence Assessment

| Claim                                                                           | Confidence      | Basis                                                             |
| ------------------------------------------------------------------------------- | --------------- | ----------------------------------------------------------------- |
| MDP-1 (safety vs. agency) is irreducible at current tooling                     | **High**        | Structural — every gate costs latency                             |
| MDP-2 (consolidation vs. 4× reality) breaks at hook layer                       | **High**        | Direct inspection of target hook-semantic differences             |
| MDP-3 (workflow vs. hallucination-floor) survives the cross-persona convergence | **Medium-High** | Hidden premise identification is inferential                      |
| MDP-4 (personal vs. shipped) is the pivotal unresolved tension                  | **Very High**   | Cross-synthesis unanimity on "unknown user mix"                   |
| MDP-5 (substrate bet) cannot be deferred at implementation                      | **High**        | Every real call commits to a substrate                            |
| MDP-6 (restraint vs. gaps) is zero-sum by design                                | **High**        | Fragility-cliff frame forces this                                 |
| MDP-7 (meta-skill leverage) is experiment-resolvable                            | **Medium**      | Systems-thinker's own caveat + untested at scale                  |
| Determinism wins ties with judgment                                             | **Medium-High** | Priority ordering is implicit; never stated in persona findings   |
| Five of seven MDPs are owner-resolvable                                         | **High**        | Only MDP-4 is philosophically unresolvable; others reduce to bets |
| Research has hit its ceiling                                                    | **High**        | Further persona analysis adds text without reducing tension       |

**Overall confidence in the MDP set as the right framing**: **High**. The seven points are the places where two load-bearing values pull in opposite directions and no research move relaxes the pull. The maintainer's next action is a decision document responding to each MDP directly.

---

_End of tension mapping._
