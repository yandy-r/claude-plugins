# Strategic Research Report: `ycc` Plugin Ecosystem Enhancements

**Research Date**: 2026-04-20
**Subject**: Useful additions to the `ycc` Claude-plugin bundle for networking,
Kubernetes, containers, virtualization, network security, cloud (AWS/Azure/GCP),
and vendor platforms (Cisco, Fortinet, Juniper, Palo Alto Networks).
**Method**: Asymmetric Research Squad — 8 persona agents, 2 crucible agents,
4 emergent-insight agents, run under a shared agent team (`drpr-ycc-plugin-ecosystem`).
**Output Directory**: `docs/research/ycc-ecosystem-enhancements/`

---

## Executive Synthesis

Fourteen independent research agents, probing this question from eight distinct
perspectives and three synthesis layers, converged on a single structural
conclusion: **the vendor-matrix expansion that superficially fits the stated
domain list (one skill per Cisco / Fortinet / Juniper / Palo Alto; one per
AWS/Azure/GCP; one for K8s; one for virtualization) is a build trap.** It is
exactly the pattern that killed Puppet-for-networking, Cisco onePK, HP Opsware,
and — in the plugin world — the 2025-2026 Booklore and Ingress-NGINX single-
maintainer collapses.

What survived the crucible is a much smaller, sharper punch list: **3-6
net-new artifacts, all workflow-shaped or safety-shaped, plus a hooks
directory the bundle doesn't yet have.** The evidence is convergent:

1. **MCP is the 2026 substrate.** Palo Alto Cortex MCP (official beta), Cisco
   and Juniper MCP exposure (2025-2026), Nautobot MCP 3.1 (April 14-15, 2026),
   Itential's 56-server catalog — every major network/security vendor is
   shipping an MCP or actively moving to. A `ycc` skill that re-implements
   what a vendor MCP already does is a dumb wrapper and loses by obsolescence
   within ~6 months.
2. **The empty niche is the Orient phase of the OODA loop.** Observe is
   automated (telemetry/SIEM). Act is automated (Ansible/Terraform/vendor
   APIs). Orient — cross-vendor blast-radius reasoning, change-review
   narrative, drift explanation — is human-bottlenecked and unoccupied.
   This is where LLMs _actually_ add value that isn't already shipped.
3. **Safety primitives are deterministic, not probabilistic.** The K8s
   wrong-context failure mode, the ACL-misorder failure mode, and the
   AWS Kiro 13-hour outage failure mode are prevented by hooks (scripts
   with exit code 1), not by skills (prompt guidance). `ycc` has no
   `hooks/` directory today. That is the single loudest absence in the
   current inventory.
4. **Workflow-shaped > vendor-shaped.** Thirty years of history — RANCID
   (1997, still running) through Ansible networking (2015) through
   Terraform's `plan` (2014) — says the durable archetype is the
   diff-review-apply loop, not the vendor-platform play.
5. **The single maintainer must ship a theory of subtraction, not just
   addition.** With `ycc` at ~140 source artifacts × 4 compat targets
   (~560 effective artifacts), and the context-rot tipping point
   estimated at ~70-90 skills, net additions must be small. **A meta-
   skill that audits the bundle itself** (sunset review, skill telemetry)
   is a load-bearing anti-fragility move that no persona independently
   proposed but which emerges from the combination.

**Key Findings**:

1. **Build a `hooks/` directory** with 4-6 PreToolUse hooks covering
   production-context guard, destructive-command blast-radius gate,
   secret-in-config scanner, change-window enforcement, and cross-vendor
   commit-confirm requirement. This is the single highest-value intervention.
2. **Ship 3-4 workflow skills**, not a domain-per-vendor matrix:
   `ycc:network-change-review` (meta-skill), `ycc:config-drift`
   (RANCID-native in MCP form), `ycc:mop` (Method-of-Procedure with
   auto-rollback from diff), and `ycc:evidence-bundle` (compliance
   artifact collection).
3. **Ship 1-2 reflexive meta-skills** that fight sprawl:
   `ycc:skill-telemetry` (track invocation rates) + `ycc:sunset-review`
   (nominate unused skills for archive). These defer the context-rot
   cliff and encode maintainability as a first-class product feature.
4. **Reject** the seven-domain vendor skill expansion as currently framed.
   Nine of 15 candidates identified by the negative-space persona are
   duplicated by vendor MCPs, mature FOSS (Nornir/NAPALM/Netmiko/PyATS),
   or foundation-model fluency (cloud Terraform, containers).

**Most Surprising Discovery**: the 8-persona convergence on "workflow over
vendor" was not a matter of taste — it emerged as physics. Vendor-specific
knowledge has a 5-10 year half-life (IOS-XE syntax drifts, PAN-OS releases
renumber, kubectl APIs deprecate on 6-month cadences). Workflow patterns
(diff, review, rollback, blast-radius) have a 30-year half-life because they
are shaped by human change-management discipline, not by vendor releases.
The pattern-recognizer phase called this out explicitly: "the convergence on
workflow > vendor is information half-life, not opinion."

**Highest-Impact Insight**: the `ycc` inventory currently has NO `hooks/`
directory. This is the single most actionable takeaway. Of all possible
additions, the one with the highest value-to-maintenance ratio is creating
that directory and shipping one PreToolUse hook (wrong-cluster guard) that
demonstrates the pattern. Everything else can be evaluated in the context
of "we have a hooks layer now."

---

## Multi-Perspective Analysis

### Theme 1: The Vendor-Matrix Temptation (and Why It Fails)

#### Overview

The natural reading of "I also do networking / K8s / cloud / Cisco / Fortinet
/ Juniper / Palo Alto" is "build one skill or agent per listed item." Every
persona independently pushed back on this reading.

#### Historical Context (Historian, Archaeologist)

- **Cisco onePK (2013-2014)**: vendor-specific SDK that Cisco themselves
  quietly deprecated in favor of NETCONF/YANG + DNA Center. Documentation
  stopped generating August 2014. Developers who invested in onePK
  re-wrote against standards.
- **Puppet network-device model (2012-2019)**: Puppet Enterprise 2019
  deprecated the per-device agent-proxy model because "push config, verify,
  diff" is what operators needed and Puppet gave them certificate management.
- **HP Opsware + BladeLogic**: acquired at peak ($1.65B, $800M), absorbed
  into big-vendor portfolios, effectively frozen in time within a decade.
  Vendor-specific infra-automation has a consistent ~10-year half-life.
- **Every vendor-specific platform play of the 2010s (onePK, SLAX, TOSCA,
  OpenFlow-centric SDN) failed or transformed beyond recognition.** The
  primitives survived; the "platform" framing didn't.

#### Current State (Journalist, Systems Thinker)

- Every major vendor is shipping MCP servers in 2025-2026. Palo Alto Cortex
  MCP is in official beta. Cisco and Juniper have community-to-official
  MCP momentum. Itential catalogs 56 production-ready MCPs.
- `ycc` currently has 140 source artifacts (≈560 effective across 4 targets)
  and a single maintainer. Systems-thinker estimates the context-rot cliff
  at ~70-90 skills, i.e., the bundle is near its structural limit.
- Vendor MCPs will outcompete any Claude-side vendor wrapper by API
  directness — they make the actual API call; a prompt only tells the
  model what to say.

#### Future Outlook (Futurist, Systems Thinker)

- Every infra domain converges on the same spine by 2027: **NL intent →
  typed IR → validate → plan → HITL → deploy → verify → rollback**. MCP
  is the transport; vendors who don't expose one become invisible to
  agentic workflows by 2027-2028.
- Per-vendor Claude skills become dead weight within 12-24 months of
  vendor MCP GA. Workflow skills that _call_ the MCP layer appreciate
  over the same interval.

#### Critical Perspective (Contrarian, Negative-Space)

- LLMs empirically hallucinate vendor CLI syntax at rates that matter for
  prod. The mitigations that work are (a) RAG against vendor docs, (b)
  commit-confirm workflows on the device side, (c) Batfish / pre-deploy
  simulators. **A skill prompt does none of these.**
- Adding 20+ vendor-specific artifacts to a 4-target-multiplied bundle
  burns maintainer budget with no corresponding safety gain. The
  single-maintainer Ansible Galaxy data (multiple deprecated
  vendor-specific collections) is the base-rate prediction.

#### Cross-Domain Insights (Analogist)

- Linux kernel layering: `ycc` belongs in the userspace/workflow layer.
  Driver-level (vendor API) work belongs in Ansible/Nornir/vendor MCPs.
  This is a **rejection heuristic**, not an architectural preference.
- Terraform Registry's three-tier model: Official (vendor-owned) vs.
  Verified vs. Community. A single maintainer cannot credibly play
  vendor. Workflow-named skills (`network-change-review`) honestly signal
  what `ycc` actually is.

#### Evidence Quality

- **Confidence**: High
- **Sources**: Primary historical record (Cisco/Puppet/HP public
  deprecation docs), primary journalist sourcing with dates, explicit
  vendor MCP announcements, peer-reviewed LLM-on-vendor-CLI hallucination
  research.
- **Contradictions**: None material. Journalist and Contrarian agree on
  the MCP landscape; Historian and Futurist agree on the vendor-platform
  half-life. The only tension is dosage (how far to trim), not direction.

---

### Theme 2: The Safety-Primitive Empty Niche

#### Overview

Five of eight personas independently identified safety/audit primitives
(hooks, blast-radius labels, rollback, provenance, context-guards) as the
largest current gap in the `ycc` inventory. The negative-space persona's
inventory scan found **no `hooks/` directory at all**. The contrarian
argued that every proposed "safety skill" is actually a hook in disguise.
The analogist mapped this directly onto Gawande's _communication checklist_
category.

#### Historical Context

- RANCID (1997) was a safety primitive before anyone called it that:
  read-only, diff on every run, email on change, version in CVS. Still
  running in production 29 years later. **Safety shapes outlive platform
  shapes.**
- Change-management rituals (MOP, pre-check, post-check, change window)
  codified in the 1990s-2000s still define competent ops practice. These
  are not dead disciplines; they are absent from current AI tooling.

#### Current State

- AWS Kiro's 13-hour Cost Explorer outage (Oct 2025) is the canonical
  recent example: AI bot with operator permissions, no peer review, no
  blast-radius gate. AWS's own post-incident guidance explicitly called
  for _constrained permissions + mandatory peer review + gradual rollout_,
  all of which are deterministic primitives, not prompts.
- K8s wrong-context incidents (kubectl delete against prod) are documented
  routinely. The solved pattern is `$KUBECONFIG` separation + a pre-tool
  hook that reads `kubectl config current-context`. A _skill_ reminding
  the model to check is weaker than a hook that blocks.

#### Future Outlook

- By 2027, blast-radius guardrails and typed-IR validation become table
  stakes for agentic infra work. Bundles that ship these today compound
  positively against ones that don't. The investment is front-loaded;
  the payoff is compounding.

#### Critical Perspective

- The contrarian's harshest point: a safety _skill_ that tells the model
  to "be careful with kubectl" creates false confidence. The user thinks
  safety exists; it does not. Only a PreToolUse hook that runs a script
  with exit code 1 is actually safety. **Conflating skills and hooks in
  the safety domain is the single most dangerous unintended consequence
  of naive bundle expansion.**

#### Cross-Domain Insights

- Gawande's Checklist Manifesto layering maps cleanly:
  - **Skill = adaptive judgment** (progressive disclosure, how to reason)
  - **Script = task checklist** (deterministic steps with fail-loud)
  - **Hook = communication checklist** (force a pause + surface info at
    the choke point before the action happens)
- All three layers are needed. A skill without a hook is a book. A hook
  without a skill is a tripwire without context.

#### Evidence Quality

- **Confidence**: High.
- **Sources**: AWS post-incident guidance (primary), vendor CLI
  commit-confirm documentation (primary Cisco/Junos/PA), Gawande
  (primary), natkr.com K8s context-safety pattern (secondary).

---

### Theme 3: Workflow-Shaped Skills That Survive Every Hype Cycle

#### Overview

When personas were asked what to build (rather than what to avoid), a
remarkably small set of patterns recurred. All were workflow-shaped, not
domain-shaped.

#### The Surviving Workflow Patterns

**Diff → Review → Apply → Rollback** (RANCID archetype, 1997-present):
proven across 30 years and every modern DevOps tool. A `ycc:network-
change-review` skill that synthesizes diffs, narrates blast radius, and
emits a rollback plan maps onto the single most-copied pattern in
network-automation history.

**Archive → Drift-Detect → Explain** (RANCID variant, still unsolved at
the workflow layer): detect config drift between intended state (git) and
observed state (device). `ycc:config-drift` using the archaeologist's
cook-and-diff pattern, but wired through MCP servers for capture.

**MOP (Method of Procedure) generation** (carrier/enterprise discipline,
1990s-present, conspicuously absent from modern AI tooling): a MOP is a
pre-change document that includes commands, expected output, rollback
commands, and abort criteria. `ycc:mop` that takes a proposed diff and
generates the MOP narrative automatically — with the rollback commands
derived by running the diff backwards — is a genuine revival candidate
with no modern equivalent.

**Pre-check / Post-check gates**: before a change, capture baseline
state (routes present, sessions up, policies intact); after, compare.
Pre-cloud networks did this with `show ip route | include` catalogs.
Not packaged as a reusable artifact anywhere in modern tooling.

**Evidence Bundle** (compliance workflow): collect SOX/PCI/HIPAA/
FedRAMP-shaped artifacts from a change (who, what, when, approvals,
diffs, pre/post state). Compliance auditors currently rebuild this
manually per engagement. `ycc:evidence-bundle` is novel and fills
an unaddressed niche.

#### Why These Survive

Pattern-recognizer identified the underlying physics: **workflow patterns
have a much longer half-life than vendor facts** because they are shaped
by human change-management discipline, not by product releases. A skill
that encodes "here's how to review a change" still works when Cisco
renames IOS-XE; a skill that encodes "here's IOS-XE syntax" does not.

#### Evidence Quality

- **Confidence**: High.
- **Sources**: primary network-operations literature (RANCID, Oxidized,
  MOP templates from carrier practice), archaeologist research on
  forgotten-but-worth-reviving patterns, convergent practitioner
  writing (Pepelnjak, Packet Pushers, NetworkToCode).

---

### Theme 4: The Meta-Skill / Anti-Sprawl Layer

#### Overview

The innovation-agent phase produced the research's most unexpected insight:
the bundle needs a **theory of subtraction** as a first-class feature. No
individual persona proposed this; it emerged from recombining the
systems-thinker's fragility-cliff warning with the negative-space persona's
15-candidate punch list.

#### The Proposal

- **`ycc:skill-telemetry`** — a skill/hook pair that logs which skills
  Claude invokes (or offers) per session, with a local-only persistence
  store. Enables data-driven decisions about which skills earn their
  descriptor slot and which are candidates for archive.
- **`ycc:sunset-review`** — a meta-skill that reads the telemetry,
  applies a rule ("skills unused in N days are nominated for archive"),
  and produces a review document. The maintainer then decides, but the
  work of finding candidates is automated.
- **`ycc:skill-fitness`** — a meta-skill that audits the bundle for
  skills with inconsistent descriptor length, outdated references,
  broken `${CLAUDE_PLUGIN_ROOT}` paths. Runs as part of bundle-release
  preflight.

#### Why This Is Load-Bearing

With `ycc` approaching its context-rot cliff, every new addition raises
the noise floor on every other skill. If the bundle ever lets bad skills
stay (dead code = dead skills), quality compounds downward. The meta-skill
layer inverts this: every skill is on a clock and must earn its slot.

#### The Productive Contradiction

Systems-thinker warned against "adding to fix addition" (a common
organizational pattern). Innovation-agent's response: meta-skills aren't
"more skills in the bloat sense" — they are _rules_ for the system
(Meadows's leverage point #5) delivered as skills. A meta-skill reduces
bundle size over time by enabling principled subtraction. This is the
one class of addition where the fragility argument inverts.

#### Evidence Quality

- **Confidence**: Medium-High.
- **Sources**: Meadows leverage-point framework (primary), CNCF
  graduation + archive process (analog), unused-code detection
  literature (secondary). The application to plugin bundles is novel
  and unproven, which is reflected in the confidence level.

---

### Theme 5: Vendor-Specific Skills — The One Case That Earns Its Keep

#### Overview

The crucible phase surfaced one narrow case where vendor-specific content
passes the "why not use vendor MCP / native tooling" test: **documenting
LLM-failure patterns per vendor**, not vendor knowledge itself.

#### The Proposal

`ycc:llm-infra-pitfalls` — one skill modeled on TerraShark's pattern
(Feb 2026): explicitly enumerates documented LLM failure modes per
provider (`count` vs `for_each`, `sensitive` vs `write_only`, missing
`moved` blocks; Cisco vs Junos route-redistribution idioms; kubectl
context assumptions; `terraform import` CLI vs declarative blocks).
The skill is not "how to write Terraform." It is "here are the specific
mistakes the model has made and will make again if you don't pattern-
match them."

This passes the contrarian's bar because it is _adverse to the model_:
it tells the reader where the model is wrong, rather than giving the
model more vocabulary to confidently generate. Competing MCPs don't
address this — they are tool-call interfaces, not meta-knowledge.

#### Evidence Quality

- **Confidence**: Medium-High.
- **Source**: TerraShark (Medium, Feb 2026) provides the template; the
  generalization to a per-domain pitfalls index is inferential but
  well-grounded.

---

## Evidence Portfolio

### High-Confidence Findings

- **MCP is the 2026 de-facto standard for vendor/cloud integration.**
  Cross-persona triangulated (Journalist, Contrarian, Futurist,
  Analogist). Implication: duplicating MCP is net-negative.
- **`ycc` has no `hooks/` directory.** Observed directly; this is the
  loudest single absence.
- **Workflow-shaped skills outlive vendor-shaped skills by ~3-5x.**
  Historian's 30-year record + futurist's 2027 trajectory agree.
- **Single-maintainer-vertical-expansion is a well-documented
  collapse pattern.** Booklore (2026), Ingress-NGINX (2026), Tidelift
  survey (46-58% burnout), multiple Ansible Galaxy
  deprecation records.
- **The 4-target multiplier is not theoretical.** Every skill ×
  (Claude/Cursor/Codex/opencode). Every hook × 4. CONTRIBUTING.md
  already flags this, but the full cost is under-weighted in mental
  models.

### Medium-Confidence Findings

- **Context-rot tipping point ~70-90 skills.** Systems-thinker's
  estimate, extrapolated from Anthropic context-engineering literature
  and Vercel's 56% skill-non-invocation evals. The _shape_ is certain;
  the _number_ is an estimate.
- **AWS Kiro 13-hour outage.** Directionally confirmed; exact duration
  not double-sourced. Use as "significant multi-hour AWS outage
  attributable to AI agent with excess permissions" in the report body.
- **Pre-cloud MOP/pre-check/post-check patterns deserve revival in
  AI-native form.** Archaeologist's strong case; no modern equivalent
  exists, but the user-demand side is not directly measured — it is
  inferred from "these disciplines worked in carrier networks and are
  conspicuously absent from AI tooling."

### Speculative Findings

- **Meta-skills (sunset-review, telemetry) will successfully defer the
  context-rot cliff.** Theoretically sound but empirically untested at
  bundle scale. Plausibility: high. Needs validation via actual
  deployment.
- **Vendor MCPs will commoditize vendor-specific `ycc` skills within
  12-24 months.** Directional prediction; specific vendor timelines
  vary.

### Critical Contradictions

#### Ship dosage: 3-4 artifacts vs. 10-15 artifacts

- **Position A** (Contrarian): only 3-4 of the naively proposed
  additions are defensible. All must be hooks or narrow diagnostic
  skills.
- **Position B** (Negative-Space): 15 candidates scanned, 6 in
  P0/P1 tier, because the failure modes they prevent are concrete
  and sourced.
- **Evidence quality**: A has higher primary-source density (OSS
  burnout research, explicit vendor MCP evidence); B has higher
  specificity (per-artifact mapped to a real workflow gap).
- **Resolution**: contradiction-mapper classified this as a **dosage,
  not direction** disagreement. Both agree that hooks > skills for
  safety and workflow > vendor for knowledge. The ACH analyst
  adopted H4 (4-6 artifacts + hooks layer) as the midpoint that
  respects both positions.

#### Temporal framing: archaeology-revival vs. MCP-native future

- **Position A** (Archaeologist): revive RANCID-era discipline as
  Claude-native skills.
- **Position B** (Futurist): assume MCP is substrate; skills should
  be MCP-client orchestrators.
- **Resolution**: not actually a contradiction. The diff-archive-rollback
  _discipline_ is the content; MCP is the _transport_. `ycc:config-drift`
  can be archaeologist-ethos + futurist-plumbing at the same time.

#### Tipping-point warning vs. specific build lists

- **Position A** (Systems-thinker): bundle near context-rot cliff.
- **Position B** (Negative-space et al.): here are 15 specific
  high-value additions.
- **Resolution**: scale-of-analysis difference. The cliff is a
  _constraint_, not a _blocker_. It budgets the expansion at 3-6
  artifacts, not zero. This budget was respected by the final
  ranked punch list.

---

## Strategic Implications

### Ranked Build Recommendation (The Punch List)

This is the decision-document output the research was commissioned to
produce. Each entry has: **Form**, **Domain**, **Value prop**, **Concrete
failure mode prevented / workflow unlocked**, **Reason NOT to build**,
**Effort**, **Priority**.

#### P0 — Ship First

**P0.1 — `hooks/` directory + wrong-context PreToolUse hook**

- **Form**: Hook (shell script + settings.json snippet)
- **Domain**: K8s / cloud / vendor-CLI safety
- **Value prop**: deterministically blocks destructive commands against
  production contexts.
- **Prevents**: kubectl delete against prod, `terraform apply` against
  prod workspace, `az/gcloud` against prod subscription.
- **Counter-argument**: Claude Code / Cursor / Codex / opencode have
  _different_ hook models; each addition is 4 hooks. Also: users may
  disable hooks that fire too often (false-positive fatigue).
- **Effort**: M (need 4-target matrix + reference hook + docs).
- **Priority**: P0.

**P0.2 — `ycc:network-change-review` (workflow meta-skill)**

- **Form**: Skill (+ helper scripts)
- **Domain**: networking (vendor-neutral)
- **Value prop**: takes a proposed config diff, enumerates blast
  radius, emits rollback plan, surfaces cross-device dependencies.
- **Prevents**: apply-without-review failures; shipping a change
  whose rollback path wasn't pre-computed.
- **Counter-argument**: overlap with commercial tools (Batfish, vendor
  management systems). `ycc`'s differentiator is _narrative synthesis_,
  not simulation.
- **Effort**: M.
- **Priority**: P0.

**P0.3 — `ycc:config-drift` (RANCID pattern on MCP transport)**

- **Form**: Skill (+ scripts, + integration points for vendor MCPs when
  available)
- **Domain**: networking / cloud config drift
- **Value prop**: compares intended state (git source-of-truth) vs.
  observed state (pulled via MCP or CLI wrapper), narrates deltas.
- **Prevents**: "someone touched prod via console" silent-drift
  incidents.
- **Counter-argument**: NetBox + Nautobot already do inventory; RANCID
  - Oxidized already do archive. `ycc`'s role is the _explain and
    reconcile_ narrative, not the storage.
- **Effort**: M.
- **Priority**: P0.

#### P1 — Ship After P0 Lands and Proves Out

**P1.4 — `ycc:mop` (Method-of-Procedure generator with derived rollback)**

- **Form**: Skill
- **Domain**: change management (vendor-neutral)
- **Value prop**: given a proposed change, produces the MOP document
  with pre-check commands, apply commands, post-check commands, and
  rollback commands (rollback derived by reversing the diff).
- **Prevents**: ad-hoc changes without documentation; rollback plans
  that exist only in the operator's head.
- **Counter-argument**: template-heavy; may be over-engineered for
  homelab work. Scope to production contexts.
- **Effort**: S-M.
- **Priority**: P1.

**P1.5 — `ycc:skill-telemetry` + `ycc:sunset-review` (anti-sprawl pair)**

- **Form**: Meta-skill pair (+ shared helper for local telemetry store)
- **Domain**: bundle hygiene
- **Value prop**: makes the context-rot cliff observable and manageable;
  encodes maintainability as a first-class feature.
- **Prevents**: bundle bloat-to-collapse failure mode (Booklore
  analog, Ingress-NGINX analog).
- **Counter-argument**: telemetry collection in a local-only skill
  ecosystem is non-trivial to implement well; risk of
  premature-optimization.
- **Effort**: M (telemetry), S (sunset-review).
- **Priority**: P1.

**P1.6 — `ycc:llm-infra-pitfalls` (anti-hallucination checklist)**

- **Form**: Skill (content-only)
- **Domain**: cross-domain LLM failure modes
- **Value prop**: enumerates documented LLM failure modes per vendor/
  provider; adverse-to-model prompting.
- **Prevents**: blind trust in plausible-looking config output.
- **Counter-argument**: content-only skills age if not maintained; must
  be paired with a sunset discipline.
- **Effort**: S.
- **Priority**: P1.

#### P2 — Maybe, or Only Conditional on User Feedback

**P2.7 — `ycc:evidence-bundle` (compliance artifact collection)**

- **Form**: Skill (+ scripts that collect git log, diff, approval
  signatures)
- **Domain**: compliance (SOX/PCI/HIPAA/FedRAMP)
- **Value prop**: turns a change into a compliance-ready evidence pack.
- **Prevents**: auditor-driven rework.
- **Counter-argument**: audience is narrow (regulated industries); may
  not match owner's workload.
- **Effort**: M-L.
- **Priority**: P2 (owner-dependent).

**P2.8 — `ycc:pre-check` / `ycc:post-check` (change-window discipline)**

- **Form**: Skills (possibly collapsed into `network-change-review`'s
  scope)
- **Domain**: change management
- **Value prop**: capture+compare baseline/after state around a change.
- **Counter-argument**: significant overlap with P0.2; may be better
  as _internal capabilities_ of `network-change-review` than standalone
  artifacts.
- **Effort**: S (if subsumed into P0.2), M (if standalone).
- **Priority**: P2 (evaluate absorption vs. separation after P0.2 lands).

### Explicit REJECT Decisions

- **`ycc:cisco-ios`, `ycc:fortinet-fortios`, `ycc:junos`, `ycc:pan-os`**:
  vendor-specific skill trees. Rejected on MCP-duplication grounds and
  hallucination-risk grounds. Build `network-change-review` and let it
  call vendor MCPs when available.
- **`ycc:k8s-day2` (as a domain-skill)**: rejected — `kubectl`, `kubectx`,
  `kubens`, `k9s`, `stern`, `kubescape`, Krew index already occupy this
  niche; foundation-model fluency is high. A kubectl-context-safety
  HOOK (under P0.1) is the right form.
- **`ycc:aws` / `ycc:azure` / `ycc:gcp`**: rejected — foundation-model
  training is strongest here; Terraform + vendor MCPs cover orchestration;
  marginal skill value is lowest of all proposed domains.
- **`ycc:virtualization`**: rejected — fragmented audience (ESXi post-
  Broadcom, Proxmox, KVM, XCP-ng), Terraform providers already cover
  automation, maintainer attention cost high relative to value.
- **`ycc:container-security`**: rejected — Trivy/Grype/Syft/Cosign
  already saturate this space CI-natively; foundation-model fluency
  high. No gap to fill.
- **`ycc:sd-wan` / `ycc:routing` / `ycc:switching` design skills**:
  rejected most strongly — Pepelnjak's 30-year critique applies
  directly; networks aren't automatable by prose; commercial tooling
  (Batfish, NetBox) operates below the prompt layer.

### Stakeholder Impacts

**The maintainer (owner)**:

- **Opportunity**: 3-4 high-leverage additions that unlock the
  owner's stated infra workflows.
- **Threat**: the vendor-matrix trap burns 12+ months of evenings.
- **Action**: adopt the punch list. Reject PR requests for
  vendor-parity additions with an explicit rationale ("ycc is a
  userspace/workflow bundle").

**Dev users** (existing `ycc` audience):

- **Impact**: neutral-to-positive. Meta-skills + hooks tighten the
  bundle; they don't add noise to dev workflows.
- **Risk**: if infra skills balloon past P0-P1, dev-skill selection
  degrades. The telemetry/sunset pair mitigates this.

**Netops/secops users** (hypothetical):

- **Impact**: P0.1-P0.3 create real, differentiated value unavailable
  elsewhere.
- **Note**: the research can't size this audience; owner should use
  3+ personal uses in 60 days as the threshold before formalizing
  each addition.

### Leverage Points

Ranked by Meadows's framework (applied by systems-thinker):

1. **LP #3 (Goal)**: make the bundle's goal explicit in README/
   CONTRIBUTING — "ycc is a meta-workflow bundle, not a reference
   library." Every proposal judged against that sentence. **Highest
   leverage**, minimal effort.
2. **LP #5 (Rules)**: add "`3+ uses in 60 days`" rule for new skill
   promotion; add a sunset rule for unused skills. These are policy
   edits, not code.
3. **LP #6 (Information flow)**: build the telemetry/sunset meta-skill
   pair (P1.5). This instruments the system so LP #5 can be enforced
   from data rather than judgment.
4. **LP #10-12 (Parameters)**: add/remove skills. This is where the
   punch list lives, but it is the _lowest-leverage_ class of
   intervention — the ones above amplify or nullify these.

### Unintended Consequences to Watch

- **Safety theater**: if `ycc:k8s-context-guard` ships as a skill
  (not a hook), users trust safety that doesn't exist. **Mitigation**:
  safety artifacts ship as hooks, period. The "skill for safety"
  pattern is explicitly rejected.
- **Descriptor Goodharting**: as skill count approaches the cliff,
  authors pressure-test descriptor length to compete for selection.
  **Mitigation**: publish a descriptor style guide; enforce a
  ~150-character cap.
- **Meta-skill paradox**: `ycc:skill-telemetry` could itself become
  dead code. **Mitigation**: include it in its own telemetry; if
  `ycc:skill-telemetry` itself is never invoked, the sunset-review
  prompt surfaces that fact honestly.
- **Vendor MCP race obsolescence**: `ycc:config-drift` written
  against vendor CLI will go stale when vendor MCPs ship. **Mitigation**:
  architect as an MCP-client-first skill with CLI fallback, not the
  reverse.

---

## Research Gaps (Owner-Side Unknowns)

These are the questions the research **cannot answer**; the owner must
resolve them before implementing the punch list:

1. **Actual monthly domain weighting**. If the owner's work is 60%
   networking and 40% K8s, the prioritization looks different than if
   it is 20% each across five domains. The punch list assumes
   broadly-balanced time distribution.
2. **Homelab vs. multi-tenant production context**. Hooks with
   production-context semantics (P0.1) behave differently in a homelab
   (annoying) vs. prod (lifesaving). Pick a default based on actual
   context.
3. **Whether `ycc` should expose a reference MCP client layer** or
   assume users wire MCP per session. This determines whether hooks
   can inspect MCP tool calls or only bash commands.
4. **User audience size**. `ycc` is a public bundle but user count
   is unknown. If primarily the owner's personal tool, Chain C
   (restraint) is uncomplicated. If a broader audience has emerged,
   R2 (adoption dynamics) may justify slightly more aggressive
   shipping.

---

## Temporal Analysis

### Historical Patterns (Past 30 years)

- **RANCID (1997)** is the canonical success: read-only, diff-based,
  git-native-before-git, still running. Every successful infra-automation
  tool has wrapped its diff-review-apply loop.
- **Every vendor-platform play failed or was transformed beyond
  recognition**: onePK, SLAX, TOSCA, OpenFlow-centric SDN, HP Opsware,
  BladeLogic. Half-life ~10 years.
- **Single-maintainer-vertical-expansion is the most-documented OSS
  failure mode** in the 2020s. Booklore, Ingress-NGINX, xz — the
  mechanism is administrative overload, not code quality.

### Current Dynamics (2025-2026)

- MCP ecosystem crossed from experimental to substrate in 2025. Every
  major vendor shipping or moving to MCP.
- AI-in-ops hype cycle at or near Peak of Inflated Expectations;
  Pepelnjak's "AI is the new SDN" critique is the counterweight.
- Claude Code plugin marketplace maturing, but quality variance is
  the dominant problem (36% keep rate in curated 2026 reviews).
- `ycc` at ~140 source artifacts, ~560 effective. Near but not
  yet at fragility cliff.

### Future Trajectories (2027-2030)

- **Consensus**: NL intent → typed IR → validate → plan → HITL →
  deploy → verify → rollback becomes the universal spine. MCP is
  table stakes. Blast-radius guardrails become default.
- **Contrarian**: much of the current "AI for network ops" hype
  recedes by 2028 as the hallucination-at-commit-time failure mode
  gets publicly documented. The tools that survive are ones that
  structurally preserve human-in-the-loop.
- **Wild card**: vendor MCP standardization may accelerate (Linux
  Foundation AI AAIF fold-in) or fragment (major vendor defects from
  the standard). Either way, `ycc` should be MCP-client-first rather
  than MCP-implementation.

---

## Novel Hypotheses (from Innovation-Agent synthesis)

### NH1: "Theory of Subtraction" as a first-class bundle feature

- **Combines**: Systems-Thinker + Negative-Space + Archaeologist
- **Rationale**: no persona proposed meta-skills independently, but
  recombining "bundle near fragility cliff" + "needs specific shipping
  candidates" + "revive forgotten discipline (maintenance rituals)"
  produces this.
- **Testable prediction**: if `ycc:skill-telemetry` + `ycc:sunset-review`
  ship, at least one skill will be principled-archived within 6 months.
- **Impact**: high. Defers the context-rot cliff indefinitely.
- **Feasibility**: M.

### NH2: RANCID-on-MCP (archaeological pattern in a 2026-native form)

- **Combines**: Archaeologist + Futurist
- **Rationale**: RANCID's diff-archive-emit pattern is the most-copied
  pattern in network automation; MCP is the 2026 transport. Their
  intersection is a new artifact: `ycc:config-drift` that uses vendor
  MCPs (where available) for read-only capture and git for archival.
- **Testable prediction**: shipped alongside a concrete vendor MCP
  (e.g., Palo Alto Cortex), produces drift reports operators actually
  read.
- **Impact**: high. Fills the Orient-phase niche without duplicating
  MCP Act-phase work.
- **Feasibility**: M.

### NH3: Blast-radius-reasoner as the keystone Orient-phase artifact

- **Combines**: Analogist (OODA) + Contrarian (deterministic-over-
  probabilistic) + Historian (commit-time is where AI fails)
- **Rationale**: the hook blocks; the blast-radius-reasoner explains
  _why_ it blocked and _what to do_. Together they span Gawande's
  communication checklist (hook) + adaptive judgment (skill).
- **Testable prediction**: combining the P0.1 hook with a `ycc:
network-change-review` skill produces measurably better change
  outcomes in home-lab trials before shipping.
- **Impact**: high. Demonstrates the skill+script+hook trio
  concretely.
- **Feasibility**: M.

### NH4: MOP-as-policy, not MOP-as-document

- **Combines**: Archaeologist + Futurist (intent-based networking
  trajectory)
- **Rationale**: the traditional MOP is a human-readable doc. The
  2027-trajectory version is a _policy object_ the agentic system
  can consult during deploy ("is step 3 blocked? was post-check
  successful?"). `ycc:mop` can emit both forms from the same
  underlying structure.
- **Testable prediction**: a machine-readable MOP from `ycc:mop`
  can be consumed by a hypothetical future agentic deploy pipeline
  without re-parsing.
- **Impact**: medium-to-high. Positions `ycc` for 2027-2028 agentic-
  ops patterns without shipping them yet.
- **Feasibility**: M-L.

---

## Methodological Notes

### Research Execution

- **Personas deployed**: 8 (Historian, Contrarian, Analogist, Systems
  Thinker, Journalist, Archaeologist, Futurist, Negative Space Explorer)
- **Crucible agents**: 2 (ACH Analyst, Contradiction Mapper)
- **Emergent-insight agents**: 4 (Tension Mapper, Pattern Recognizer,
  Negative-Space Analyst, Innovation Agent)
- **Total search queries** (documented across persona reports): ~170
- **Team infrastructure**: `drpr-ycc-plugin-ecosystem`, 14 tasks
  registered up-front with cross-batch dependencies; shutdown between
  phases; team deleted after Phase 3.

### Evidence Quality Distribution

- **Primary sources**: vendor docs (Cisco DevNet, Junos, PAN-OS),
  Anthropic MCP announcements, CNCF process docs, peer-reviewed
  LLM-hallucination research (arXiv 2307.04945, 2501.08760),
  Terraform Registry + Ansible Galaxy governance records, AWS
  public incident post-mortems, OSS maintainer burnout surveys
  (Tidelift 2024).
- **Secondary sources**: credentialed practitioner writing
  (Pepelnjak, Hightower, Majors, Packet Pushers, NetworkToCode,
  Addy Osmani, a16z MCP analysis, HumanLayer's CLAUDE.md analysis,
  Letta context-bench).
- **Synthetic**: aggregated market reports (treated as confirming,
  not load-bearing).
- **Speculative**: all futurist 2027+ predictions marked as
  speculation.

### Confidence Assessment

- **Overall confidence**: High on the historical + current-state
  claims and their implications (themes 1-3); Medium-High on the
  meta-skill / anti-sprawl recommendation (theme 4) — theoretically
  grounded but empirically untested at bundle scale; Medium on the
  specific priority ordering within the punch list (sensitive to
  owner's actual domain weighting).

### Limitations

- **Owner-side weighting unknown** — 3 open questions in the
  verification log cannot be closed without owner input.
- **`ycc` user audience unknown** — research cannot resolve the
  "personal tool vs. public bundle" question, which materially
  affects R2 (adoption) prioritization.
- **Meta-skill efficacy unproven** — NH1 (theory of subtraction) is
  theoretically sound but no reference implementation exists in the
  Claude Code plugin ecosystem yet. Early-adopter risk.
- **Vendor MCP maturity varies** — Palo Alto is official, Cisco/
  Juniper are transitional, Fortinet is community-only. `ycc:config-
drift` (P0.3) has rougher footing against Fortinet than against
  Palo Alto.

---

## Recommendations

### For the Maintainer (Owner)

1. **Ship P0 in order**: hooks directory → wrong-context hook →
   `ycc:network-change-review` → `ycc:config-drift`. Do not start
   additional work until P0 lands.
2. **Make the goal explicit** (LP #3 play): add one sentence to
   README/CONTRIBUTING: "`ycc` is a meta-workflow bundle focused on
   checklist + judgment + communication primitives, not a reference
   library of vendor coverage." This reframes 90% of expansion-request
   debates into trivial closes.
3. **Adopt the "3+ uses in 60 days" personal-use test** for any new
   skill before formalizing it into the bundle. Prototype locally
   first; ship only if used.
4. **Reject vendor-parity PRs explicitly** with a link to the goal
   sentence above. The Linux kernel userspace/driver layering heuristic
   is your backup: "this belongs in Ansible/Nornir/vendor MCP; `ycc`
   is userspace."
5. **Budget the meta-skill investment** (P1.5) before you hit ~80
   skills. If you ship 6-10 net-new artifacts over 6 months and don't
   instrument bundle fitness, the cliff arrives without warning.

### For Further Research (Owner-Led)

1. **Run a 30-day personal use audit**: track which `ycc:` invocations
   happen in actual work. This resolves RQ5 (value-to-maintenance
   ratio) with data rather than intuition.
2. **Survey vendor MCP status** each quarter. Adjust P0.3
   (`ycc:config-drift`) integration plan as MCPs mature.
3. **Prototype P0.1 (wrong-context hook)** first. If the 4-target
   matrix is uglier than expected, revise the shared-helper approach
   before adding more hooks.

---

## Conclusion

The user's question — "what new agents, skills, hooks, and scripts would
genuinely enhance the `ycc` ecosystem, given my work in networking, K8s,
containers, virtualization, network security, and cloud?" — has a
counter-intuitive answer: **not many, and not what the domain list
suggests.**

The domain list encodes the user's _work_, not the user's _tooling gap_.
The tooling gap is smaller and more specific: `ycc` has no hooks layer,
no workflow-shaped meta-skills for cross-vendor change management, and
no anti-sprawl instrumentation. Those are the gaps. Filling them
unlocks genuine value across all seven stated domains simultaneously —
because they are shaped by _how humans change infra_, not by _which
vendor's device is being changed_.

The vendor-per-skill matrix, which the domain list naturally suggests,
is the graveyard pattern. MCP is eating that work.

**Bottom Line**: build a `hooks/` directory + 3 workflow skills
(`network-change-review`, `config-drift`, `mop`) + 1 meta-skill pair
(`skill-telemetry`/`sunset-review`). Reject every per-vendor,
per-cloud, and per-domain skill request with a link to the bundle's
stated purpose. Revisit in 6 months with telemetry data.

---

## Appendices

### A. Research Artifacts

- Objective: `objective.md`
- Persona findings (8 files): `persona-findings/{historian,contrarian,analogist,systems-thinker,journalist,archaeologist,futurist,negative-space}.md`
- Crucible analysis: `synthesis/crucible-analysis.md`
- Contradiction mapping: `synthesis/contradiction-mapping.md`
- Tension mapping: `synthesis/tension-mapping.md`
- Pattern recognition: `synthesis/pattern-recognition.md`
- Negative-space synthesis: `synthesis/negative-space.md`
- Innovation synthesis: `synthesis/innovation.md`
- Evidence verification: `evidence/verification-log.md`

### B. Persona Summaries

- **Historian**: 30-year lineage argues workflow-shape > vendor-shape;
  RANCID (1997) is the durable archetype; vendor-platform plays are
  where careers and codebases go to die; single-maintainer vertical
  expansion fails by administrative overload.
- **Contrarian**: of ~20 naive proposals, 3-4 are defensible, all as
  hooks or narrow diagnostic skills; vendor MCPs outcompete Claude-side
  wrappers; Pepelnjak/Hightower/Majors consensus is that fundamentals
  matter more than AI layers.
- **Analogist**: `ycc` should be Terraform-Registry-Official-tier
  (small, owned, keystone); Linux kernel userspace/driver split is
  the rejection heuristic; Gawande's checklist+judgment = hook+script+
  skill trio is the highest-transfer mechanism.
- **Systems-Thinker**: bundle near context-rot cliff (~70-90 skill
  tipping point); the proposed expansion is an LP #12 move in LP #3
  clothing; needs skills-of-skills composition and a sunset rule;
  xz/event-stream single-maintainer pattern is dormant but present.
- **Journalist**: MCP is the 2026 de-facto standard; every major
  vendor is shipping one; duplicating is net-negative; empty space is
  cross-vendor change-review workflow skills.
- **Archaeologist**: top revivals are RANCID-native config-drift,
  MOP generator with auto-rollback from diff, and pre/post-check
  gates; these pre-cloud disciplines are absent from all modern AI
  tooling.
- **Futurist**: every infra domain converges on the NL-intent-to-
  rollback spine by 2027; MCP is substrate, blast-radius guardrails
  are table stakes, telemetry is adversarial; invest in 3 P0
  primitives, avoid per-vendor skins.
- **Negative-Space Explorer**: the loudest silence in `ycc` is
  safety/audit primitives; no hooks directory, no blast-radius tags,
  no provenance capture; 15 ranked candidates, P0/P1 = hooks +
  change-review + evidence-bundle + CMDB-lookup + context-guard +
  blast-radius-tags.

### C. Complete Artifact Inventory

14 agents ran; 13 artifacts produced:

```
docs/research/ycc-ecosystem-enhancements/
├── objective.md
├── persona-findings/
│   ├── historian.md
│   ├── contrarian.md
│   ├── analogist.md
│   ├── systems-thinker.md
│   ├── journalist.md
│   ├── archaeologist.md
│   ├── futurist.md
│   └── negative-space.md
├── synthesis/
│   ├── crucible-analysis.md
│   ├── contradiction-mapping.md
│   ├── tension-mapping.md
│   ├── pattern-recognition.md
│   ├── negative-space.md
│   └── innovation.md
├── evidence/
│   └── verification-log.md
└── report.md (this file)
```

_This research was conducted using the Asymmetric Research Squad
methodology on the ycc plugin bundle at
`/home/yandy/Projects/github.com/yandy-r/claude-plugins`. It does not
include any source changes — it is purely a decision document._
