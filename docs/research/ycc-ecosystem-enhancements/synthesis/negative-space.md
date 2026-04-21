# Negative Space: Critical Unanswered Questions & Research Gaps

**Role**: Negative Space Analyst (Asymmetric Research Squad, Phase 3 synthesis)
**Date**: 2026-04-20
**Distinction from Phase 1**: Phase 1's `negative-space-explorer` scanned the external landscape (ecosystem-wide silences, avoided topics, under-served stakeholders). This phase 3 analysis inventories what remains UNKNOWN _after_ all 8 persona findings + crucible + contradiction mapping — the gaps inside our own research.
**Inputs**: objective.md, 8 persona findings, crucible-analysis.md (ACH), contradiction-mapping.md, verification-log.md.
**Mandate**: Prioritize by impact on the build decision. A gap that doesn't change the decision is low-priority; a gap that _reverses_ H4/H7/H3 ordering is high-priority.

---

## Executive Summary

The research produced an unusually high-confidence primary recommendation (**H4 workflow skills + hooks**, fallback H7 tight hybrid, with H3 hooks layer as prerequisite under both) backed by 6/8-persona convergence and a +21 ACH disconfirmation score against the alternatives. That confidence is justified _given the evidence available_. But four owner-side unknowns, three empirical gaps, two theoretical blind spots, and two practical implementation gaps sit directly underneath the recommendation — and at least two of them, if resolved differently than the research assumes, **reverse the hypothesis ordering**.

The single most load-bearing unknown is **the owner's actual month-to-month domain weighting** (contradiction-mapper's Contradiction #8, verification-log U1). Every build list in the research implicitly assumes the self-reported 7-domain scope reflects current daily work. If the actual split is 70% dev-adjacent / 20% K8s / 10% everything else, H7 becomes the correct choice over H4 and the archaeological P0 list shrinks. If it is 60/40 networking-deep / everything else, H4 is justified and `network-change-review` passes the CNCF-adoption test. The research cannot resolve this — it is a self-report question.

The single most load-bearing _empirical_ gap is the absence of a measured context-rot threshold for Claude Opus 4.7 at skill-descriptor scale. Systems-thinker's 70-90 estimate is an analyst synthesis with explicitly **medium-low confidence**; Vercel's "56% skill non-invocation" is a different eval on a different model; Anthropic's 55K-134K tool-token data is for MCP tools, not Claude Code skill descriptors. The tipping-point claim is directionally solid but numerically synthetic. A 2× error on the threshold (say, 140-180 instead of 70-90) reopens H1's margin and partially rescues per-vendor content.

The single most load-bearing _practical_ gap is that nobody in the research has empirically authored a working hook that propagates cleanly across Claude + Cursor + Codex + opencode. E29 ("every hook is 4 hooks") and F2 ("safety primitives are the empty niche") together say hooks are the highest-leverage artifact class — but the research never measured the actual cross-target authoring cost, and `ycc/hooks/` does not yet exist. If the real cost is 8+ hours per hook (per ACH discriminator #5), H3 is meaningfully less attractive relative to H4 than the scoring assumes.

The most conspicuous gap in the research itself is that **we did not study actual failure modes in Claude Code sessions on the owner's real machine**. We have vendor-side incident data (Kiro 13h outage, Meta SEV1, Cursor billing), third-party plugin-keep data (composio 12%, buildtolaunch 36%), and Anthropic telemetry-adjacent data (auto-approve trajectories). We have zero data on what has actually bitten _the owner_ while using ycc for infra work. The CNCF-adoption test (analogist's "used ≥3 times in last 60 days") is exactly the missing instrument.

---

## Critical Unanswered Questions (ranked by decision impact)

### Tier A — Questions that reverse the hypothesis ordering if answered one way vs. another

#### Q1. What is the owner's actual month-to-month workflow weighting across the 7 stated domains?

- **Why it reverses the decision**: every build list in the research assumes self-reported 7-domain breadth is real. If actual weighting is concentrated in 1-2 domains, H2 (zero-build) or H7 (tight hybrid with just archaeological P0) dominates. If weighting is balanced, H4 is right. If it is 80% networking-specific, _some_ vendor-adjacent content becomes defensible (not H1, but narrow vendor-pattern skills).
- **Why research cannot resolve it**: self-report only. The contrarian (Uncertainty 3) and systems-thinker (Contradictions #2) flagged this; the contradiction-mapper (#8) elevated it to "very high" severity; the verification log labeled it U1. Nobody has the data.
- **Minimum instrument to resolve**: a 60-day retrospective: which of `{dev, K8s, containers, virt, netsec, cloud, vendor}` did the owner actually touch, how often, and when was the last time an AI assistant would have meaningfully helped (not just been present)?
- **Decision implication if answered**: resolves H4-vs-H7 directly; partially reopens H1 only for the one domain that actually dominates.

#### Q2. Does ycc have a downstream audience at all, or is it primarily the maintainer's personal toolkit?

- **Why it reverses**: if ycc is pure personal toolkit, R2 (brand/adoption loop, systems-thinker) is dormant and every maintenance-tax argument gains weight — H7 narrows further, hooks-only H3 becomes fully justifiable. If there is a real external audience, the cross-vendor workflow-synthesis niche (E24) is worth filling even at higher cost, and H4 becomes clearly dominant.
- **Why research cannot resolve it**: no public adoption metrics surface. Systems-thinker flagged this as load-bearing; negative-space (persona) noted "actual adoption rates" as an explicit knowledge gap.
- **Minimum instrument**: GitHub traffic/install data, marketplace install counts, issue filer diversity.
- **Decision implication**: shifts the value side of the value/cost ratio by roughly 2× in either direction.

#### Q3. Is the 70-90 skill context-rot tipping point accurate for Claude Opus 4.7 at ycc's descriptor shape?

- **Why it reverses**: systems-thinker's estimate is explicitly labeled medium-low confidence. If real threshold is ~140-180 skills (plausible at 1M context with better descriptor handling), H1's "25-40 new artifacts" becomes survivable and the blanket rejection weakens. If real threshold is ~50-60 (possible if descriptors interact badly with skill tool-use routing), current ycc is _already_ over and every hypothesis needs replanning.
- **Why research cannot resolve it**: nobody has run a Vercel-style eval against ycc's actual descriptor set. Vercel's 56% non-invocation is a different eval. Anthropic's 55K token-bloat number is MCP tools, not skills.
- **Minimum instrument**: a small eval suite (systems-thinker's LP #8 proposal) that measures skill-selection precision against a held-out task set at current 45-skill count and at simulated +5/+10/+20 skill counts.
- **Decision implication**: the research's entire "bundle is near fragility cliff" frame pivots on this number. The ordering H1 < H2 < H5 < H6 < H3 < H7 < H4 holds at 70-90; at 150+ the spread tightens considerably.

#### Q4. Will vendor MCPs mature and stay maintained through 2026-Q4 / 2027-Q1 for the vendors the owner actually uses?

- **Why it reverses**: futurist's entire thesis (H1 elimination) depends on MCP substrate holding. Contrarian's vendor-skin-is-dead-weight argument depends on it. If 3+ of {Cisco, Juniper, Fortinet, Palo Alto, Arista} are still community-MCP-only by 2027-Q1 (as PAN-OS currently is), then temporary wrappers are defensible for the transition period (futurist flagged this explicitly as Contradiction #3 in their own findings). H1's margin widens from -21 to roughly -12 under this condition.
- **Why research cannot resolve it**: it is a forecast. Futurist gave base-case probabilities; journalist documented current shipment state (as of 2026-04); neither predicts 2027-Q1 maintenance state.
- **Minimum instrument**: a 6-month re-check of vendor MCP commit frequency, issue responsiveness, and first-party vs. community status.
- **Decision implication**: the "reject per-vendor skills" conclusion is robust _even under this uncertainty_ because the cost of building vendor skins now is paid now and cannot be refunded when MCPs finalize. But a transitional wrapper skill (marked sunset-when-MCP-ships) becomes defensible.

### Tier B — Questions that significantly narrow uncertainty but don't reverse ordering

#### Q5. What fraction of the owner's target users are air-gapped / OT / regulated-no-cloud-inference?

- **Why it matters**: negative-space (persona) estimated 10-20% but flagged as inferential. If air-gap fraction is ≥ 30%, any H4 skill that depends on external MCP is unusable for that chunk of the audience, which elevates archaeologist's "Expect-era login helpers" from P2 to P1 (H7 territory) because it operates locally. If it is < 5%, air-gap accommodation is noise.
- **Why research cannot resolve it**: no direct survey.
- **Decision implication**: shifts specific artifact priority within H4/H7; does not change hypothesis ordering.

#### Q6. What is the actual cross-target authoring cost for one production-quality hook spanning Claude + Cursor + Codex + opencode?

- **Why it matters**: E29 claims "every hook is 4 hooks" but never measures the actual hours. ACH discriminating evidence #5 asked this directly: "Time one hook end-to-end across 4 targets. If > 8 hours, H4 faces a real budget problem and H3 becomes relatively more attractive."
- **Why research cannot resolve it**: the research did not author a hook to measure. The repo currently has `hooks-workflow` (a skill _about_ hooks) but zero shipped hooks.
- **Minimum instrument**: ship one example hook (e.g., context-guard) and measure elapsed time for author + validate + document across 4 targets.
- **Decision implication**: ships-cost calibration. Doesn't flip ordering; sets realistic scope for H3/H4 rollout.

#### Q7. Which of archaeologist's P0 patterns has the owner personally hand-rolled or pasted from Stack Overflow in the last quarter?

- **Why it matters**: direct evidence for H4-vs-H7 discriminator. ACH discriminating evidence #4 framed this exactly.
- **Why research cannot resolve it**: owner self-report needed.
- **Decision implication**: resolves H4-vs-H7 cleanly. Each hit on `{config-drift, mop, pre-check, post-check, cook-and-diff}` is evidence for including it in the ship list.

### Tier C — Questions worth knowing but don't constrain the build decision

#### Q8. What are the actual LLM hallucination rates for the specific vendor CLIs the owner uses most (as distinct from the Cisco/Junos benchmarks cited)?

- **Why it matters less**: the hallucination-exists claim is settled (E3); ordinal ranking is sufficient. Exact rates would only matter for fine-tuning per-vendor priority _within_ H4's vendor-adapter adapter layer, which is itself P2 work.

#### Q9. How many ycc users run which targets (Claude/Cursor/Codex/opencode)?

- **Why it matters less**: the 4× multiplier applies to _shipping_ cost regardless of user split. Would only matter if the owner chose to drop a target, which is out of scope.

#### Q10. What is the exact probability distribution of xz-style social-engineering risk at ycc's current scale?

- **Why it matters less**: systems-thinker's P ≈ 0.05 is probably within the right order of magnitude. The mitigation (48-hour cool-off on hook PRs) is low-cost enough to ship regardless.

---

## Research Gaps by Category

### Empirical Gaps

**E-gap 1 — Context-rot threshold specific to Claude Opus 4.7 / ycc's descriptor shape.**
What we have: Vercel evals at 56% non-invocation (unclear model, unclear corpus); Anthropic 55K-134K MCP tool token data; systems-thinker analyst estimate of 70-90. What we don't have: a measurement on this bundle at this model.

**E-gap 2 — LLM hallucination rates for specific vendor CLIs (beyond the Cisco/Junos benchmarks).**
What we have: IRAG at 97.74% with RAG, LLM-alone ceiling ~85%, Mondal et al. on route-map vs. routing-policy confusion, TerraShark on Terraform-specific patterns. What we don't have: benchmark data for Fortinet FortiOS, Palo Alto PAN-OS CLI, Arista EOS, vendor-specific SD-WAN syntaxes, modern K8s CRDs, cloud CLI parameters at the edge (AWS service-level quirks, Azure Graph peculiarities).

**E-gap 3 — Claude Code auto-approve rate specifically for infra-touching tools.**
What we have: general 20% → 40%+ trajectory across session history. What we don't have: breakdown by tool category. Infra tools likely have a _lower_ auto-approve rate because blast-radius is high; without that data we cannot tune hook warn-vs-block thresholds accurately.

**E-gap 4 — Actual plugin-keep rates in infrastructure contexts.**
What we have: composio 12%, buildtolaunch 36%, both self-reported among general users. What we don't have: keep rates specifically among net/sec/ops engineers.

**E-gap 5 — Cross-target hook authoring time-cost (see Q6).**
What we have: the claim "every hook is 4 hooks." What we don't have: the number.

**E-gap 6 — Validator runtime at 2× / 3× current skill count.**
What we have: 13 validators currently, no specific runtime figures. What we don't have: projection for whether the pre-push hook becomes intolerable at expansion scale (systems-thinker Chain B, unintended consequence #3).

**E-gap 7 — Actual MCP client posture inside ycc sessions.**
Verification-log U3: "whether ycc has an MCP client layer or expects users to wire MCP servers per session." This is partly ycc-configuration-state, partly behavioral-during-use. Nobody measured it.

### Theoretical Gaps

**T-gap 1 — No formal model of "skill composability" in plugin ecosystems.**
H5 (pure composition / skills-of-skills) survives as an internal design principle but not a primary strategy because **nobody in the research, or in the cited literature, has a formal model for when composition scales and when it doesn't**. Systems-thinker explicitly flagged: "Meta-skill effectiveness unproven at this scale. 'Skills-of-skills' is a sound theory but I have not surveyed concrete evidence of routers outperforming leaf skills at 50+ skill bundle sizes."

- What we'd need: theoretical work on skill-composition overhead as a function of (descriptor count, compositional depth, model context-handling capability). Absent.

**T-gap 2 — No theory of "descriptor economics" under skill-selection routing.**
We know descriptors have cost (token-budget) and value (disambiguation). We have no model of the optimal descriptor length and vocabulary per skill, nor of the game-theoretic equilibrium when multiple authors compete for the same selection slot (R3 Goodhart loop). The systems-thinker sketched the mechanism but did not formalize.

**T-gap 3 — No unified model of "blast radius" across heterogeneous tool calls.**
The futurist recommends a blast-radius hook as P0. The journalist documents every vendor converging on "blast-radius disclosure" as 2027 table stakes. **Nobody defines what blast radius means operationally.** Is it `(number of resources touched) × (reversibility cost) × (dependency fanout)`? Does it differ between `kubectl apply` (declarative, reversible) and `terraform apply` (stateful, harder to reverse) and `cisco conf t` (imperative, write-mem gate)? Without a cross-domain formal definition, a blast-radius hook defaults to per-tool heuristics that won't compose.

**T-gap 4 — No theory of "keystone skills" that holds up across maturity stages.**
Analogist's keystone-species framing is evocative but the cross-domain evidence is not cleanly operationalized. The "use ≥3 times in 60 days" CNCF-adoption test is a proxy, not a theory. We don't know what makes a skill genuinely keystone (enables N downstream workflows) vs. merely frequent.

**T-gap 5 — No framework for "4× compat tax" efficient scheduling.**
E23 and E29 establish the 4× multiplier exists. Nobody modeled when to author simultaneously vs. author-for-Claude-then-port. The sync.sh pipeline encodes a source-then-generate discipline but not a cost-optimal authoring order.

### Practical Implementation Gaps

**P-gap 1 — No working reference hook across 4 targets.**
The `hooks-workflow` skill describes the pattern; no installable hooks ship. This is both the single clearest complementary absence (E10) _and_ the reason we cannot measure P-gap 2 below.

**P-gap 2 — No measured descriptor-length vs. selection-precision curve for ycc specifically.**
We cannot tune skill descriptors to minimize R3 Goodharting without this curve. The LP #7 intervention (cap descriptor length, reject keyword-stuffing) is therefore a guess, not a calibrated rule.

**P-gap 3 — No reference implementation of the NL → IR → validate → plan → confirm → deploy → verify spine.**
Futurist's E11 shows four independent research tracks converged on this shape in 2025. No ycc artifact yet conforms. Without a reference, H4's `network-change-review` skill risks being written vendor-specifically (missing the point) or too abstractly (not usable).

**P-gap 4 — No cataloged per-vendor regex set for "cook-the-output" volatile-field filtering.**
Archaeologist named this as RANCID's load-bearing lost art; the `_shared/scripts/cook-diff.sh` proposal in negative-space's punch list (item 1/drift) needs this catalog. The research mentioned RANCID's per-vendor logins but did not extract or convert the regex sets.

**P-gap 5 — No "telemetry sanitizer" shared helper.**
Futurist's E25 (AIOpsDoom adversarial telemetry) mandates this. Journalist documented vendor write-path safety patterns (Juniper `block.cmd`, vlanviking `PANOS_READONLY`). Nobody has compiled these into a reusable `_shared/scripts/telemetry-sanitizer.sh` pattern or tested it.

**P-gap 6 — No integration recipe with `Batfish` / `Containerlab` / `opa` / `kubeval` as validator substrate.**
H4's `network-change-review` needs pluggable validators. The research identified them but did not specify the integration contract (input format, expected exit codes, error surface).

**P-gap 7 — No "MCP client posture" documented for ycc.**
If an H4 skill is supposed to prefer vendor MCPs and fall back to CLI, what is the contract? Which MCPs are assumed installed? What is the detection mechanism? Journalist's MCP landscape is a menu; ycc's consumption protocol is unwritten.

**P-gap 8 — No governance mitigation wired in for hook supply-chain risk.**
Systems-thinker recommended "48-hour cool-off for hook PRs" (Unintended Consequence #4, xz-pattern mitigation). No concrete workflow, issue template, or CODEOWNERS pattern exists.

### Owner-side Gaps

**O-gap 1 — Domain weighting (Q1).**
**O-gap 2 — Downstream audience (Q2).**
**O-gap 3 — Personal hand-rolled patterns (Q7 — archaeologist P0 list).**
**O-gap 4 — MCP client layer posture (verification-log U3 / P-gap 7).**
**O-gap 5 — Multi-tenant vs. homelab primary use case (verification-log U2).**
Hooks for production blast-radius warn differently than hooks for a homelab. The research flagged this explicitly but did not resolve.
**O-gap 6 — Tolerance for maintenance tax / willing cadence for re-audit.**
Systems-thinker's B3 (complexity-collapse tail risk) is probability-weighted by how often the owner is willing to re-audit. No data.

---

## Gaps in the Research Itself (Honest Self-Critique)

Flagging gaps the research team should own — places where we were weaker than we could have been.

### G1. We studied the ecosystem more than we studied the owner.

We have a very detailed map of vendor-MCP landscape (journalist), hallucination research (contrarian), historical ancestry (historian + archaeologist), and scaling math (systems-thinker). We have almost no data on the owner's actual workflow. Every persona treated the objective's 7-domain statement as ground truth. **That is the biggest methodological gap.** A proper personalization pass (30-minute structured interview or 60-day workflow retrospective) would compress three of the top-four unanswered questions.

### G2. We cited persona findings as if they were primary evidence.

Systems-thinker's 70-90 tipping point, futurist's 25% Gartner, analogist's Gawande layering — these are _synthesized_ claims inside persona findings. The ACH matrix scores them as evidence items (E17, E12, E15) with various quality tags, but the crucible analysis treats the persona's _synthesis_ as if it were the underlying data. This is evidence-of-evidence, and while it's how the method works, we should be honest that the +21 C-I score for H4 is softer than it looks.

### G3. We did not validate the evidence standards in the objective.

The objective set evidence hierarchy (Primary > Secondary > Synthetic > Speculative) but the personas mixed tiers freely. For example, Gartner's "25% of network configs by GenAI by 2027" appears as both a primary-source claim (when cited from Gartner directly) and a synthetic-aggregator claim (when cited via a blog that cites Gartner). The research did not consistently distinguish.

### G4. We smoothed some contradictions we said we wouldn't.

The objective explicitly said "contradictions between 'more tooling helps' and 'avoid bloat / stay lean' are preserved, not smoothed." The ACH analysis preserved these at the hypothesis level but the crucible's Executive Summary ends with "H4 is the leading primary strategy" — a smoothed synthesis. The contradiction-mapper did a better job preserving tensions. The two synthesis documents disagree on how much smoothing is appropriate and that disagreement is not surfaced.

### G5. We did not sanity-check our own skill-authoring discipline.

Every persona critique of "don't add skills you can't sustain" applied to ycc. We did not apply the same critique to our own output — this research produces ~300K of documentation that the single maintainer now must integrate. The research tax is itself a maintenance cost we introduced.

### G6. We addressed the 7 domains unevenly.

The objective listed 7 domains in parallel (networking, K8s, containers, virt, netsec, cloud, vendor platforms). The research disproportionately addressed networking and vendor platforms; K8s got moderate depth (context-guard, day-2 ops); containers, virtualization, and cloud got thin coverage. Virtualization especially — Proxmox/KVM/ESXi — is arguably under-researched. The "reject per-vendor matrix" conclusion is conveniently compatible with this unevenness; we should flag that our uneven coverage partially _produced_ the recommendation.

### G7. We did not deeply examine what happens at +5 skills vs. +15 vs. +40.

The research bundles H1 (25-40 skills) against H4 (4-6) with a 70-90 tipping point claim. It does not model the sensitivity of the recommendation to the actual expansion size. A tight H1 (10-12 skills, carefully chosen) might survive better than the research's framing suggests. We eliminated H1 mostly by appeal to the bias list in objective.md and to evidence about unchecked scope creep, not by modeling a disciplined H1.

### G8. We did not integrate compatibility with the owner's existing private tooling.

The research treated ycc as if it exists in isolation. It does not. The owner has a shell, aliases, MCP configs, VS Code/IDE setup, private dotfiles. An H4 workflow skill that duplicates what the owner's shell aliases already provide is net-negative. We have no data on what private tooling exists.

### G9. We treated "air-gapped" as a binary.

Negative-space flagged air-gap as a barrier for 10-20% of users. The real gradient is subtler: air-gap for inference vs. air-gap for data exfil vs. regulated-but-connected. The research did not taxonomize.

### G10. We assumed Claude Opus 4.7 is static.

The research framed the decision at a single model version. Claude Opus 5.x in 2026-H2 / 2027 may absorb descriptors gracefully (systems-thinker's Uncertainty #3), which would delay the fragility cliff. Or it may introduce new primitives (e.g., first-class skill clusters) that make meta-skills (H5) trivially cheap. The research did not hedge on model evolution beyond a paragraph of caveat.

---

## Key Insights

### Insight 1 — The owner-side gaps are the center of gravity.

Q1, Q2, Q7 (domain weighting, audience, hand-rolled patterns) are not research gaps; they are owner-report gaps. The research has hit its information ceiling on everything downstream of these three. Any additional research time should shift from more external scanning to direct owner elicitation.

### Insight 2 — The empirical gap on context-rot is the only technical gap that could reverse the recommendation.

Everything else tunes priorities; this one reorders hypotheses. If someone built the small eval suite systems-thinker recommends as LP #8, and the threshold turned out to be 150+, the research's entire "bundle near fragility cliff" frame collapses. This is the highest-leverage measurement to take.

### Insight 3 — The theoretical gaps are real but non-blocking.

We don't need a formal theory of skill composability or descriptor economics or blast radius to ship H3 hooks + H7 archaeological P0. We would need them to ship H5 (pure composition) confidently — which is why H5 got demoted to a design principle.

### Insight 4 — The practical gaps are the ones that MUST be closed before shipping.

P-gaps 1 (no reference hook), 3 (no NL→IR spine reference), 4 (no cook-and-diff regex catalog), 7 (no MCP client posture) are all "ship-blockers" — shipping H4 without closing them produces half-artifacts that fall exactly in the chasm Crossing-the-Chasm / Gawande warn against.

### Insight 5 — The research itself has real maintenance cost.

G5 is not just self-critique; it's real decision input. 300K of documentation must be triaged or archived by the maintainer before the recommendation can be acted on. Most of the documentation is supporting evidence that does not need to live in `ycc/`. An `archive/` move or deletion policy is needed.

### Insight 6 — The "hooks are the empty niche" claim is evidentially strong but operationally under-specified.

F2 in the verification log is "High confidence" and 5 of 8 personas convergent. But the research never shipped one hook to measure. The confidence on the _diagnosis_ is not confidence on the _implementation cost_. P-gap 1 is the correctable gap.

### Insight 7 — We have evidence against H1 that would survive most counter-arguments.

H1 is gone. The -21 ACH score is unusually decisive. Even under favorable assumptions (context-rot threshold at 150, owner weighting 60% networking-deep, vendor MCPs slow through 2027), H1's per-vendor matrix remains dominated by H4's workflow-agnostic approach. The firmness of the H1 rejection is itself a research asset. Use it as the policy anchor in CONTRIBUTING.md.

### Insight 8 — The H4-vs-H7 discriminator is operational, not epistemic.

At +20 (H7) vs. +21 (H4), the statistical discrimination is noise. The real discriminator is whether the owner has _personally used_ change-review and evidence-bundle workflows in the last 60 days. That is a 5-minute conversation, not more research. The research has set up the decision; the owner has to make it.

### Insight 9 — Several evidence items triangulate on "the owner should ship hooks first."

Whether you reach for H3, H4, or H7, the first artifact should be a hook (context-guard or blast-radius-warn). Every surviving hypothesis agrees on this order. If the owner wants to test the 4× multiplier cost (E-gap 5 / Q6) cheaply, shipping one hook is the instrument.

### Insight 10 — Honest acknowledgment of our G1–G10 gaps is the strongest epistemic move we can make in the final deliverable.

A build-decision document that ships with named, ranked research gaps is more trustworthy than one that claims certainty. The owner is the maintainer; they will make better decisions with the gap list in hand than with a clean recommendation that papers over them.

---

## What Is Conspicuously NOT in the Research (Flagging Our Own Team's Misses)

Items the objective called out that the research addressed weakly or not at all:

- **"Air-gapped / regulated / OT markets"** — negative-space (persona) raised it; no follow-through in crucible; no per-persona analysis of what archaeologist's Expect-era patterns mean specifically for air-gap operators (where they're _still dominant_). The research bundled this as "10-20% of target audience" and moved on.

- **"Junior network engineer pipeline"** — negative-space (persona) and systems-thinker (R1 loop) touched it; ACH scored it as E28 with "M" quality; no specific coach-mode artifact proposal survived the crucible. This is a real gap.

- **"NL-to-ACL, cluster-aware context switching, cloud cost anomaly surfacing"** — the objective's "future possibilities" list. NL-to-ACL is well-covered (futurist E11, four converged research tracks). Cluster-aware context is well-covered (E30, all safety plugins converge here). **Cloud cost anomaly surfacing is entirely missing from the research.** No persona addressed AWS/GCP/Azure cost-watching as a skill candidate. This is a miss.

- **"OT / SCADA programming languages"** — negative-space flagged (ladder logic, SPARK/Ada). No follow-through anywhere.

- **"MSP multi-tenant scoping"** — negative-space flagged; no follow-through in crucible. The `--tenant` / per-tenant-fence concept didn't survive.

- **"Compliance evidence bundling (SOX/HIPAA/PCI)"** — negative-space included it as punch-list item 5 (evidence-bundle skill); ACH included it in H4; contradiction-mapper (Section "Irreconcilable #2") used it as the H4-vs-H7 discriminator. But no persona did the specific work of checking which compliance regimes the owner actually operates under. This is O-gap 1 again.

- **"Cable plan → config generation"** — negative-space flagged; entirely absent from downstream analysis.

- **"Inventory reconciliation as first-class workflow"** — negative-space flagged (NetBox Copilot); archaeologist contributed `router.db` simplicity; journalist confirmed NetBox/Nautobot as the source-of-truth layer. But no crucible-level proposal for a ycc artifact here survived, except as a P2 in negative-space's original punch list. May be under-prioritized.

- **"VS Code network extensions, JetBrains network tools, Backstage plugins"** — analogist covered VS Code and JetBrains well; Backstage well. No Eclipse, IntelliJ network-specific, no Elastic/Splunk SIEM extension comparisons. Adequate but not comprehensive.

The pattern across these misses: **negative-space (the phase 1 persona) raised more candidates than any subsequent phase had bandwidth to process.** The ACH correctly filtered aggressively; some of the filtering was under-argued. The build-decision document should note these as "not studied" rather than "rejected."

---

## Structural Observations on Research Methodology

Three meta-observations about how the research itself went:

1. **Persona method produced high-coverage breadth.** 8 personas × 15-30K each + ~300K synthesis = ~400K total. The domain map is comprehensive. Cost: reading time and the G5 maintenance tax.

2. **ACH method produced unusually clean hypothesis elimination.** H1's -21 score is decisive. But ACH rewards hypothesis-framing quality; H1 was framed as a completionist strawman that no persona advocated, so ACH killed it easily. A steelmanned "disciplined narrow H1" (10-12 vendor-adjacent skills with explicit sunset rules) was never hypothesized, so never scored. This is a methodology artifact worth naming.

3. **The contradiction-mapper and crucible agree on direction, disagree on smoothing.** Contradiction-mapper preserved the tensions; crucible synthesized a recommendation. Both are valid outputs; the owner reading only the crucible loses productive tensions worth keeping.

---

## Actionable Implications for the Final Build-Decision Document

1. Surface Q1, Q2, Q7 as **prerequisite owner questions** before the build list. Frame explicitly: "this recommendation assumes X; if X is Y, recommendation flips to Z."

2. Recommend the eval suite (systems-thinker LP #8) as the first instrumentation investment. It closes E-gap 1 and is a prerequisite for disciplined future expansion.

3. Scope the initial shipping artifact to **one hook** (context-guard or blast-radius-warn) to measure E-gap 5 / Q6 before committing to the full H3 set.

4. Archive most of this research under `docs/research/.../archive/` rather than `docs/plans/` to manage the G5 maintenance tax.

5. Note in CONTRIBUTING.md the **H1 policy rejection** as the strongest-grounded claim the research produced. Use it as the rejection heuristic for future vendor-matrix proposals.

6. Leave air-gap, OT, MSP-tenant, and junior-coach-mode as explicit "not studied this round" items rather than implicit rejections.

7. Build the cook-and-diff regex catalog (P-gap 4) and the MCP-client posture doc (P-gap 7) as documentation-only artifacts first; skills come later once the contracts are stable.

---

## Summary Table: Gap → Decision Impact

| Gap                                      | Category             | Decision Impact                   | Resolvable By              |
| ---------------------------------------- | -------------------- | --------------------------------- | -------------------------- |
| Q1 Domain weighting                      | Owner                | **Reverses H4/H7**                | 60-day self-retrospective  |
| Q2 Downstream audience                   | Owner                | **Reverses value/cost**           | GitHub/marketplace metrics |
| Q3 Context-rot threshold                 | Empirical            | **Reverses hypothesis ordering**  | Small eval suite           |
| Q4 Vendor-MCP maturity by 2027-Q1        | Empirical (forecast) | Reopens H1 partially              | 6-month re-check           |
| Q5 Air-gap audience fraction             | Owner/empirical      | Shifts priority within H4         | Survey / self-report       |
| Q6 Cross-target hook authoring cost      | Empirical            | Calibrates scope                  | Author one hook            |
| Q7 Archaeologist P0 hand-rolled count    | Owner                | Resolves H4-vs-H7                 | Owner self-report          |
| E-gap 2 Vendor CLI hallucination rates   | Empirical            | Tunes P2 priorities               | Targeted benchmarks        |
| E-gap 3 Infra-tool auto-approve rate     | Empirical            | Tunes hook thresholds             | Session analysis           |
| T-gap 1 Formal composability model       | Theoretical          | Non-blocking for H4/H7            | Future research            |
| T-gap 3 Unified blast-radius definition  | Theoretical          | Needed for H4 hook                | Design work                |
| P-gap 1 Reference hook across 4 targets  | Practical            | **Ship-blocker for H3/H4**        | Author one                 |
| P-gap 3 NL→IR spine reference            | Practical            | Ship-blocker for H4 meta-skill    | Implement one              |
| P-gap 4 Cook-and-diff regex catalog      | Practical            | Ship-blocker for drift skill      | Extract from RANCID        |
| P-gap 7 MCP client posture               | Practical            | Ship-blocker for vendor-fallback  | Document contract          |
| G1 Didn't study the owner                | Methodology          | Centered on external evidence     | Direct elicitation         |
| G6 Uneven domain coverage                | Methodology          | Partially produced recommendation | Targeted follow-ups        |
| G7 No sensitivity analysis on +5/+15/+40 | Methodology          | H1 may be over-rejected           | Scenario modeling          |

---

## Confidence Assessment

| Claim                                                | Confidence  | Basis                                            |
| ---------------------------------------------------- | ----------- | ------------------------------------------------ |
| The Tier-A questions reverse the hypothesis ordering | High        | Direct traceability through ACH scoring          |
| Q1 is the single highest-impact gap                  | High        | Every build list depends on it                   |
| The 70-90 threshold is synthetic                     | High        | Systems-thinker flagged explicitly               |
| P-gap 1 (no reference hook) is a ship-blocker        | High        | Cannot measure cost without one                  |
| H1 rejection is robust to these gaps                 | High        | -21 ACH score with high-quality disconfirmers    |
| H4-vs-H7 is owner-dependent                          | High        | Multiple personas converged on this              |
| The research's own G1-G10 gaps are real              | High        | Self-critical catalog                            |
| Cloud cost anomaly surfacing is a genuine miss       | Medium-High | Objective listed it; research did not address    |
| Closing Q1 via 60-day retrospective is feasible      | Medium      | Assumes owner willingness                        |
| The eval-suite investment closes E-gap 1             | Medium-High | Systems-thinker's proposal is sound in principle |

**Overall confidence that this gap list is approximately complete**: **Medium-High**. I surfaced ~30 gaps. A careful reader could surface more; the categories (Empirical / Theoretical / Practical / Owner / Methodology) appear exhaustive.

---

_End of negative-space analysis._
