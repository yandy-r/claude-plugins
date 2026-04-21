# Systems Thinker — `ycc` Ecosystem Expansion

**Persona**: Systems Thinker
**Date**: 2026-04-20
**Subject**: Second-order effects, feedback loops, stakeholder incentives, and leverage
points for expanding the `ycc` bundle into network / K8s / containers / virtualization /
net-sec / cloud / vendor-platform artifacts.
**Method**: Donella Meadows's 12 leverage points + Conway's Law + Goodhart's Law + Context
Engineering (Anthropic) + open-source sustainability research (xz/Log4j/event-stream).

---

## Executive Summary

The `ycc` bundle is already at or near a **fragility cliff**, and the proposed expansion
into 6 new infrastructure domains (networking, K8s, containers, virt, netsec, cloud,
vendor platforms) pushes it over. The system's dominant loop is no longer reinforcing
("more skills → more adoption"); it is balancing and negative ("more skills → context
pollution + maintenance tax → degraded per-skill signal → discovery collapse").

Current load:

- 45 skills + 52 agents + 43 commands = **140 source-of-truth artifacts**
- Each artifact is generated into **4 target bundles** (Claude, Cursor, Codex, opencode)
  → effective artifact count ≈ **~560**
- **13 validators** guard the source/generated parity (sync.sh + validate.sh chains)
- **1 maintainer**, mirroring the xz / event-stream / Log4j structural pattern

The proposal would add on the order of 20–40 new artifacts across 7 domains, fanning
out to 80–160 generated files and triggering ~2x more validator runtime. But the binding
constraint is **not CI minutes or disk** — it is (1) Claude's **effective context window**
for skill descriptors and (2) the maintainer's **attention budget** for keeping the
source→4-target→validator chain in parity.

**Headline insight**: CONTRIBUTING.md already codifies the correct system diagnosis —
"the current bottleneck is maintenance integrity (drift, inventory accuracy, generator
sync), not missing subjects." The expansion proposal pulls in the _opposite_ direction.
The highest-leverage intervention is not "add more skills" (parameters — leverage point

12. but **change the rule that governs what counts as a skill** (rules — leverage
    point #5) and **reframe the system's purpose** (goals — leverage point #3).

**Net delta for the maximal expansion** (rough, directional): total user value unlocked
≈ moderate (discoverable infra workflows for niche domains); total system fragility
delta ≈ high (context-rot risk, validator scaling, maintainer burnout replay). **Value
< fragility** for the full scope; the individual high-leverage P0/P1 additions from
other personas' punch lists can still pass this test, but the general "add a skill per
vendor" pattern fails it.

---

## System Map

```
                           ┌─────────────────────────────────────────┐
                           │         REPO OWNER (single maint.)      │
                           │   • attention budget = scarce resource  │
                           │   • models drift from skill scaffold    │
                           └───────────────┬─────────────────────────┘
                                           │ authors / edits
                                           ▼
     ┌──────────────────────────────────────────────────────────────────────┐
     │                     ycc/  SOURCE OF TRUTH                            │
     │   ycc/skills/   (45)       ← SKILL.md + references/ + scripts/       │
     │   ycc/agents/   (52)                                                 │
     │   ycc/commands/ (43)                                                 │
     │   ycc/.claude-plugin/plugin.json                                     │
     │   ycc/skills/_shared/                                                │
     └────────┬───────────────┬──────────────┬──────────────┬───────────────┘
              │               │              │              │
              │ 4× generator fanout (scripts/sync.sh → 10 generate-*.sh)   │
              ▼               ▼              ▼              ▼
     ┌──────────────┐  ┌──────────────┐  ┌─────────────┐  ┌──────────────┐
     │  .claude-    │  │ .cursor-     │  │.codex-      │  │.opencode-    │
     │  plugin/     │  │ plugin/      │  │plugin/      │  │plugin/       │
     │ marketplace  │  │ skills+      │  │skills+      │  │skills+agents │
     │ .json        │  │ agents+rules │  │agents+plug  │  │+commands+    │
     │ (native ycc) │  │              │  │             │  │opencode.json │
     └──────┬───────┘  └──────┬───────┘  └──────┬──────┘  └──────┬───────┘
            │                 │                 │                │
            │ ~13 validators (scripts/validate-*.sh)              │
            ▼                 ▼                 ▼                ▼
     ┌──────────────────────────────────────────────────────────────────────┐
     │                         CI / pre-push hook                           │
     │  (lefthook pre-push → validate.sh → fail-closed on drift)            │
     └──────────────────────────────────────┬───────────────────────────────┘
                                            │
                                            ▼
                                 ┌──────────────────────┐
                                 │  Git tag / release   │
                                 │  (bundle-release)    │
                                 └──────────┬───────────┘
                                            │
                                            ▼
     ┌──────────────────────────────────────────────────────────────────────┐
     │                         DOWNSTREAM RUNTIME                           │
     │  Claude Code harness loads skills as YAML frontmatter descriptors    │
     │  into system prompt  →  ~100 tokens per skill metadata line          │
     │  (×45 today = ~4.5 kT persistent system-prompt bulk)                 │
     │  Cursor / Codex / opencode each apply their own loading model        │
     └──────────────┬───────────────────────────────────────────────────────┘
                    │
                    ▼
     ┌──────────────────────────────────────────────────────────────────────┐
     │  USERS (unknown mix: devs, netops, secops, SREs)                     │
     │  • observe Claude's skill-selection quality                          │
     │  • experience context rot at high skill counts (Vercel evals:        │
     │    skills not invoked in 56% of cases)                               │
     │  • submit feedback / PRs / ignore                                    │
     └──────────────────────────────────────────────────────────────────────┘
```

### What breaks when you 10x the skill count

At 45→450 skills, roughly ordered by which breaks first:

1. **Descriptor prompt bloat**: ~45 kT of skill metadata permanently in the system
   prompt before the user says anything. Context-rot papers establish this degrades
   performance well below the advertised context limit.
2. **Discovery collapse**: Claude's Skill tool selects from descriptors. At 10x scale,
   descriptions must become longer and more keyword-dense to disambiguate → Goodhart's
   adversarial type kicks in (keyword stuffing) → descriptor signal erodes.
3. **Validator time**: validate.sh fans out linearly across 4 targets × skills. At 10x
   the pre-push hook becomes a nuisance → devs disable it → drift.
4. **Generator divergence**: capability gaps between Claude/Cursor/Codex/opencode force
   per-target special-casing. Each exception is a future drift bug.
5. **CLAUDE.md / AGENTS.md coupling**: owners who add skills in new domains tend to
   add rules/examples to the rules file. HumanLayer analysis: Claude's system prompt
   already has ~50 instructions; CLAUDE.md should be minimal. 10x new domains → +10x
   temptation to document them globally → instruction-following degrades.
6. **Cognitive load on maintainer**: 56 → 560 source artifacts is above what one person
   can hold in working memory. This is exactly the xz/event-stream precondition.

---

## Feedback Loops

### Reinforcing (positive) loops

**R1 — Virtuous authoring loop** (currently dominant but weakening)

```
   well-scoped skill → unlocks a workflow → owner uses it → validates value
   → authors adjacent skill → bundle breadth grows → owner's own work accelerates
```

Strong when skills solve the owner's own problems. Weakens when the domain is one
the owner touches less frequently, because the feedback signal ("does this help me?")
stops firing.

**R2 — Brand / adoption loop** (speculative)

```
   bundle ships → visible on GitHub → outside user tries it → reports issue / PR
   → maintainer engages → bundle improves → more users
```

Not currently dominant — downstream user mix is "unknown", per the brief. No public
metrics surface indicates R2 is active today.

**R3 — Descriptor keyword-stuffing loop** (adversarial, emerging)

```
   new skill added to crowded namespace → must differentiate in descriptor
   → longer descriptor / more keywords → crowds other descriptors
   → others must also expand → descriptor bloat cascade
```

This is the Goodhart mechanism applied to the skill-selection metric. At 45 skills it
is latent. At 100+ it becomes observable.

### Balancing (negative) loops

**B1 — Maintenance tax loop** (currently the dominant loop)

```
   each new skill → × 4 target generators → + validators → + regeneration on every edit
   → maintainer time per skill rises → fewer skills ship → curatorial selectivity rises
```

Healthy. This is why CONTRIBUTING.md now gates additions. The loop is working.

**B2 — Context-pollution loop** (emerging)

```
   more skills in system prompt → context pollution → Claude's skill selection degrades
   → user perceives ycc as "not working" → owner stops adding, possibly removes some
```

Not yet manifest but architecturally guaranteed at ~2–3x current scale without
structural changes. Literature (Anthropic, Letta, philschmid) is unanimous.

**B3 — Complexity-collapse loop** (tail risk)

```
   drift accumulates → validators fail → maintainer fatigues → commit velocity drops
   → social-engineering surface opens (xz pattern) OR project is archived
```

Low probability in absolute terms (this is a solo-maintainer project, not critical
infra) but the mechanism is the same: single maintainer + growing surface + no
successor = fragility.

### Dominance assessment

Current phase: **B1 dominant, with B2 as the next tipping loop**. R1 is slowing because
the marginal skill is further from the maintainer's daily workflow (proposed network /
K8s / vendor skills may be used less often than git-workflow / plan-workflow / code-
review). The expansion proposal accelerates B2 and weakens R1.

Tipping point: my estimate, based on the context-rot literature and Claude's skill
descriptor budget, is **~70–90 skills** before B2 becomes the dominant loop and
per-skill value starts to decline. The exact number depends on descriptor quality and
model version, but the _shape_ of the curve is robust.

---

## Second-Order Effects

Direct effect of adding a network-device skill: users who ask about that device get
better guidance. Claimed user value: moderate.

**Second order (likely, within weeks–months of shipping)**:

1. **Parity expectation cascade.** Ship `cisco-iosxe` → PRs arrive for `juniper-junos`,
   `arista-eos`, `fortinet-fortios`. Refusing them is a policy cost (need justification
   in CONTRIBUTING.md); accepting them expands B1 cost linearly per vendor.
2. **Refactoring pull on `_shared/`.** Multiple vendor skills will share a device-config
   diff/review pattern. Either (a) duplicate it → DRY violation, or (b) extract to
   `_shared/`, which is a cross-cutting change to a hot path touched by every skill.
3. **Rules-file growth.** Network/K8s/cloud work has its own conventions (blast radius,
   change windows, rollback). Owners are tempted to add these to CLAUDE.md globally.
   HumanLayer: every irrelevant rule in CLAUDE.md **reduces instruction-following on
   the relevant ones** because Claude applies a relevance filter.
4. **Hook-matrix audit cost.** CONTRIBUTING.md already warns: "Do not market hooks as
   uniform across targets." Infra skills typically want hook-like guardrails (wrong-
   cluster, wrong-context, config-diff). Each hook proposal now requires a 4-target
   matrix — the cost of a "hook" is really 4 hooks.
5. **Token-budget arbitrage.** Descriptors compete. Adding `kubernetes-day2` crowds the
   descriptor slot that an existing `git-workflow` was winning. Users who previously
   got the right skill auto-selected may now get the wrong one.

**Third order (months–years)**:

1. **Maintainer specialization drift.** The owner's stated domains include network/K8s/
   virt — not all are equally practiced. Bundle-authored content in weak domains ages
   faster (vendor CLIs change semantically; K8s APIs deprecate on 6-month cadences).
   Without daily use, drift is invisible until a user reports a broken example.
2. **Contributor attraction** _(positive if it happens)_. A solo-maintained bundle
   that genuinely covers netops/secops might draw co-maintainers. The xz literature
   shows this is a double-edged sword: helpful contributors and social-engineered
   ones look similar at first. Governance cost rises.
3. **Non-netops users perceive noise.** If half the bundle is infra skills and the
   user is building a Next.js app, the skill-selection model has more irrelevant
   options to rule out on every turn. Silent tax.
4. **Fork pressure.** If infra additions degrade dev UX, a fork becomes rational. Now
   the 4-target generator model must contend with an upstream fork — drift arrives
   through a new channel.

---

## Stakeholder Analysis

| Stakeholder                                          | Incentive                                     | Wins from expansion                              | Loses from expansion                                                                  |
| ---------------------------------------------------- | --------------------------------------------- | ------------------------------------------------ | ------------------------------------------------------------------------------------- |
| **Maintainer (owner)**                               | Ship useful tooling for own work              | Skills for own non-dev work                      | Attention tax, drift, burnout; loses evenings                                         |
| **Dev users**                                        | Frictionless dev workflows                    | Nothing direct                                   | Descriptor bloat, worse skill auto-selection, CLAUDE.md noise                         |
| **Netops/secops users (hypothetical)**               | Fewer config errors, blast-radius warnings    | Real value if well-scoped                        | Little, if quality is maintained                                                      |
| **Claude Code harness**                              | Enforces plugin contract; rewards conformance | Nothing                                          | Every plugin that bloats system prompt degrades perceived product quality             |
| **Cursor / Codex targets**                           | Want features parity-shipped                  | Nothing direct                                   | Capability mismatches surface more often (hooks, slash commands) — 4-target doc bloat |
| **opencode target**                                  | Parity with Claude Code                       | Nothing direct                                   | Has first-class commands, so cost is lower here                                       |
| **Vendor MCP servers** (Cisco, Fortinet, Cloudflare) | Distribute vendor expertise                   | Complement — ycc skill can orchestrate their MCP | None; if ycc skills duplicate MCP coverage, complementor conflict                     |
| **Future co-maintainers**                            | Would want minimal onboarding                 | Modular structure survives                       | Generator complexity raises onboarding cost                                           |

**The asymmetry**: the only party reliably winning from each net-new skill is a user
persona whose workflow matches that exact skill. The maintainer pays the marginal cost
on every single edit to _any_ skill because regeneration/validation is global. Payoff
is concentrated; cost is distributed. This is the classic tragedy-of-the-commons shape
**inverted**: the costs are concentrated on one person, benefits distributed across
an unknown user mix.

---

## Causal Chains

### Chain A — "Add one vendor skill" ends at "context rot"

```
Add cisco-iosxe skill
  → SKILL.md descriptor added to system prompt (~150 tokens)
  → Claude sees 46 skills at descriptor-load time (was 45)
  → on next user turn in an unrelated domain (e.g. "fix my Next.js build")
    Claude's skill-ranking pass must exclude 46 rather than 45 candidates
  → descriptor crowding raises baseline "noise floor" of system prompt
  → cumulative over 10 added skills: measurable regression in skill-selection
    precision (Vercel-style evals)
  → users perceive `ycc` as "less smart than it was last release"
  → B2 loop engages
```

### Chain B — "Add hook for wrong-cluster kubectl" ends at "4-target audit debt"

```
Add PreToolUse hook: block kubectl on prod context
  → Claude Code hook: straightforward (settings.json hook schema)
  → Cursor: different hook model — must document "not supported"
  → Codex: different model again — "not supported"
  → opencode: check whether its hook semantics match — probably needs translation
  → add per-target matrix to skill references
  → every future hook edit now requires re-auditing 4 targets
  → maintainer cost per hook ≈ 4× a "pure skill" change
  → hook proposals slow down, good guardrails don't ship, users lose a valuable
    category of protection (blast-radius prevention was a stated goal)
```

### Chain C — "Refuse to add vendor coverage" ends at "brand stagnation OR crisp focus"

```
Owner declines vendor-parity PRs per CONTRIBUTING.md
  → some users leave / fork
  → brand positioning crystallizes as "meta-workflow bundle, not vendor-surface bundle"
  → R2 (adoption) slows in volume but gains selectivity
  → R1 (virtuous authoring) stays healthy because meta-workflow is the owner's
    primary domain — feedback signal fires reliably
  → net: bundle stays under the context-rot tipping point longer
```

Chain C is currently the policy choice encoded in CONTRIBUTING.md "Scope & Guardrails".
The systems view endorses it.

---

## Leverage Points (Meadows framework, ranked high→low)

**LP #3 — Goals of the system** _(highest leverage)_

- Current goal inferred from code: "a personal but installable multi-target plugin of
  broadly useful workflows." This is the _right_ goal.
- Competing goal lurking in the expansion proposal: "a reference library of domain
  coverage across the owner's stated work areas."
- **Intervention**: make the goal explicit in README / CONTRIBUTING — "ycc is a
  meta-workflow bundle, not a reference library." Every proposal is judged against
  that one sentence. This reframes 90% of vendor-parity debates into trivial rejects.

**LP #5 — Rules of the system**

- `bundle-author` skill + `validate-ycc-commands.sh` + `compatibility-audit` are the
  rule-set. CONTRIBUTING.md encodes the policy.
- **Intervention**: add a hard rule "new skill requires ≥ 3 real workflows, ≥ 1 the
  maintainer personally ran this quarter." This filters out reference-library additions
  structurally, not by judgment. Also add a **sunset rule**: skills unused in N releases
  are auto-nominated for archive. Archive is not failure — it is the CNCF-analogous
  maturity model.

**LP #6 — Structure of information flows**

- Current discovery: YAML frontmatter descriptor loaded into system prompt.
- **Intervention**: invest in **meta-skills for routing** instead of broadening leaf
  skills. A `ycc:infra-route` skill that reads a repo signature (K8s manifests?
  Terraform? Cisco configs?) and dispatches to the right workflow is a LP #6 play —
  one descriptor in the system prompt unlocks N latent workflows without N descriptors.
  This maps to the "skills-of-skills" / "composition over quantity" pattern.

**LP #7 — Positive feedback loop gain (reduce R3)**

- **Intervention**: stop rewarding keyword-rich descriptors. Enforce a descriptor
  length cap in the bundle-author scaffold (already partially implicit). Publish a
  style guide that explicitly rejects keyword-stuffing. This is Goodhart mitigation:
  decouple "visibility in skill selection" from "keyword density."

**LP #8 — Negative feedback loop strengthening (B1)**

- **Intervention**: measure skill-selection precision in a small eval suite. Attach
  it to CI. Every new skill must not regress the suite. This is the analog of SLO-
  backed release gates. It makes the B2 loop observable before it becomes dominant.

**LP #10–12 — Parameters and stocks** _(lowest leverage)_

- Add more skills. This is what the expansion proposal is — **the least leveraged
  intervention available**, and the one most likely to backfire via B2.

---

## Unintended Consequences (ranked by probability)

1. **Descriptor Goodharting** (P ≈ 0.9 at ≥ 100 skills). Authors lengthen descriptors
   to compete for selection. Measured signal (selection rate) stops correlating with
   actual fit.
2. **CLAUDE.md bloat** (P ≈ 0.8). Infra domains tempt global rules. HumanLayer-style
   analysis shows this silently reduces instruction-following across _all_ skills, not
   just the added ones.
3. **Validator-disable** (P ≈ 0.5 at 2x scale). Pre-push hook gets too slow → one
   "fix" run with `--no-verify` becomes habit → drift accumulates invisibly → next
   release spends 2 days reconciling.
4. **Social-engineered PR** (P ≈ 0.05 but severity high). xz-pattern: a "helpful"
   contributor lands 3–4 good PRs, then slips a vendor-branded skill with an RCE
   hook or an exfiltrating script. ycc has scripts under every skill and hooks in
   settings — the surface exists. Single-maintainer review is the only defense.
5. **Forked-for-infra** (P ≈ 0.2). If the owner stays Chain-C disciplined, a contributor
   forks for "ycc-infra". This is mostly fine but now drift arrives via upstream/fork
   divergence and bug reports against the fork land in the parent repo inbox.
6. **Generator complexity spiral** (P ≈ 0.4). Each capability gap between targets adds
   a conditional in a Python generator. ≥10 conditionals per generator → the generators
   themselves become a maintenance burden larger than any one skill.
7. **Archive shame** (P ≈ 0.6). Without an explicit sunset rule, unused skills are
   never removed because removal feels like admitting failure. CNCF-style graduation +
   archive is the cultural fix.

---

## System Boundaries

- **Inside the system**: `ycc/` source, scripts/, generated bundles, validators, CI,
  marketplace metadata, maintainer attention, downstream runtime context, user
  skill-selection experience.
- **Crossing boundary**: vendor MCP servers (Cloudflare, GitHub, Vercel MCP already in
  this repo's settings), external CLIs invoked from skill scripts, CLAUDE.md /
  AGENTS.md convention shared with wider Claude ecosystem.
- **Outside**: the actual infra targets (k8s clusters, Cisco devices, AWS accounts).
  ycc never touches them; scripts invoke local tooling which does.

The critical boundary: **the skill descriptor → Claude's system prompt** is a
resource-constrained channel, not a filesystem. Treating it like free disk is the
category error behind most bloat.

---

## Emergent Properties

- **Context rot** is emergent: no single skill is "too big," but the aggregate produces
  a qualitative degradation (silent skill-selection misses) that no per-skill review
  can catch. Only an eval suite at the bundle level can see it.
- **Drift** is emergent from generator fanout: no single commit drifts, but the
  cumulative effect of N small edits where the generator wasn't rerun produces a
  state no one explicitly authored.
- **Namespace authority**: the `ycc:` prefix is a coordination primitive. Its value
  comes entirely from not being noisy. Every low-value skill dilutes it.
- **Maintainer voice**: a hidden output of the system. Users adopt `ycc` partly because
  the skills reflect a consistent editorial stance. Domain expansion risks the
  bundle reading like a collection rather than a voice.

---

## Key Insights

1. **The system is already correctly tuned at the policy layer.** CONTRIBUTING.md,
   `bundle-author/references/when-not-to-scaffold.md`, and the "meta-skills first"
   policy are doing LP #5 work. The risk is that a domain-expansion wave relaxes
   these rules implicitly.
2. **The expansion proposal is an LP #12 move in LP #3 clothing.** It's presented as
   "covering your work domains" (goal) but executed as "add parameters (skills)." The
   strong version is to _redefine the goal_ — e.g., "ycc helps the owner do infra
   work" could be served by a single "infra-toolbox" skill pointing to existing CLIs
   - MCPs, not by one skill per vendor.
3. **Composition beats coverage.** "Skills-of-skills" (a router skill that invokes
   existing workflows conditionally) has sub-linear descriptor cost. Vendor-per-skill
   has super-linear cost (each new skill raises the noise floor for every other).
4. **Every hook is 4 hooks.** CONTRIBUTING already says this, but it should be stated
   in dollars: a hook that takes 2 hours to write takes 6–8 hours to document and
   validate across targets. The expansion proposal has many hook-shaped opportunities
   (blast-radius, wrong-context). Budget accordingly.
5. **The xz/event-stream pattern is dormant but present.** Scripts under every skill +
   hooks + single maintainer + (post-expansion) larger surface + (post-expansion)
   potentially eager contributors = the exact precondition. Not imminent. Worth
   one explicit governance mitigation (e.g., "all hook / script PRs require 48-hour
   cool-off and independent review by a named trusted reviewer").
6. **The rest of the personas' recommendations should be re-filtered through this
   fragility model.** A P0 "network-change-review meta-skill" is LP #3/#5/#6 work.
   A P0 "cisco-ios-xe configurator" is LP #12. Even if both are individually useful,
   they are not equivalent in systems terms.

---

## Evidence Quality

| Claim                                                          | Source type                                            | Confidence                                           |
| -------------------------------------------------------------- | ------------------------------------------------------ | ---------------------------------------------------- |
| Descriptor metadata is in system prompt permanently            | Primary (Anthropic, Letta)                             | High                                                 |
| Context rot degrades skill selection at scale                  | Primary + benchmark (Vercel evals: 56% non-invocation) | High                                                 |
| Single-maintainer projects hit xz-pattern failure mode         | Case study (xz, event-stream, Log4j)                   | High — pattern, not prediction                       |
| CLAUDE.md bloat degrades instruction-following                 | Authoritative practitioner (HumanLayer)                | High                                                 |
| Meadows's leverage hierarchy applies outside policy            | Foundational + critiqued                               | Medium (Meadows herself calls it a work in progress) |
| 70–90 skills is the tipping point                              | Synthetic (my estimate from token budget math)         | Medium-low                                           |
| Goodhart on descriptor keywords                                | Direct application of principle, not measured in ycc   | Medium                                               |
| Generator fanout drift is the default in polyrepo-like targets | Widely documented monorepo/polyrepo literature         | High                                                 |

---

## Contradictions & Uncertainties

1. **R1 vs B2**: "more skills → more value" is true below the tipping point and false
   above it. Without an eval suite, we cannot locate ourselves on the curve. I assert
   we are still in R1 territory today and would be moving into B2 at 2x scale, but
   this is an estimate, not a measurement.
2. **User mix is unknown.** If `ycc` is primarily the maintainer's personal tool, then
   "unknown user mix" does not constrain decisions and Chain C is obviously correct.
   If ycc has a real downstream audience, R2 matters and domain expansion may be
   defensible for specific high-value niches (e.g., K8s day-2).
3. **Claude model evolution.** Descriptor-handling is a function of model capability.
   Opus 4.6 → 4.7 → 5.x may relax the context-rot ceiling. My tipping-point estimate
   is anchored to 2026 model behavior; future models may absorb more skills gracefully.
   **But** that is not a reason to add now — the cost of adding is paid now; the
   headroom is speculative.
4. **Meta-skill effectiveness unproven at this scale.** "Skills-of-skills" is a sound
   theory but I have not surveyed concrete evidence of routers outperforming leaf
   skills at 50+ skill bundle sizes.
5. **Systems framing favors restraint.** A partially-offsetting critique: Meadows's
   framework was developed for ecological/policy systems. Software plugin ecosystems
   have much shorter feedback cycles and lower irreversibility. It is possible that
   "just add it and remove it if it fails" is the right heuristic at this scale —
   which is LP #12 but cheap-to-undo LP #12. I think this critique has some force but
   loses most of its weight because descriptor pollution is _not_ cheap to undo —
   users who were stung by degraded skill-selection lose trust that is hard to regain.

---

## Search Queries Executed

1. `Donella Meadows twelve leverage points system intervention hierarchy`
2. `plugin ecosystem bloat discovery problem VS Code extension marketplace`
3. `LLM agent context window pollution skill library too many tools`
4. `Ansible Galaxy collection scale maintainability fragmentation single maintainer`
5. `open source single maintainer burnout sustainability xz Log4j`
6. `Claude Code plugin skill progressive disclosure discovery descriptor`
7. `CNCF landscape bloat sandbox incubating graduated criteria scope creep`
8. `Conway's law software documentation CLAUDE.md AGENTS.md cognitive overhead`
9. `software ecosystem tipping point contributor dry up npm left-pad event-stream`
10. `Goodhart's law metrics perverse incentives plugin registry keyword stuffing`
11. `monorepo vs polyrepo source of truth generator fanout drift`

Plus in-repo reading: `scripts/sync.sh`, `scripts/validate.sh`, `CONTRIBUTING.md`,
`CLAUDE.md`, `ycc/skills/` and `ycc/agents/` directory scans, `objective.md`.

---

## Sources

- [Leverage Points: Places to Intervene in a System (Donella Meadows)](https://donellameadows.org/archives/leverage-points-places-to-intervene-in-a-system/)
- [Twelve leverage points (Wikipedia)](https://en.wikipedia.org/wiki/Twelve_leverage_points)
- [Effective context engineering for AI agents (Anthropic)](https://www.anthropic.com/engineering/effective-context-engineering-for-ai-agents)
- [Can Any Model Use Skills? Adding Skills to Context-Bench (Letta)](https://www.letta.com/blog/context-bench-skills)
- [Skills vs MCP tools for agents (LlamaIndex)](https://www.llamaindex.ai/blog/skills-vs-mcp-tools-for-agents-when-to-use-what)
- [Context Engineering for AI Agents Part 2 (philschmid.de)](https://www.philschmid.de/context-engineering-part-2)
- [Agent Skills (Claude API docs)](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/overview)
- [Skill authoring best practices (Claude API docs)](https://platform.claude.com/docs/en/agents-and-tools/agent-skills/best-practices)
- [Progressive Discovery: A Better Mental Model for Agent Skills](https://dev.to/phil-whittaker/progressive-discovery-a-better-mental-model-for-agent-skills-51bd)
- [Writing a good CLAUDE.md (HumanLayer)](https://www.humanlayer.dev/blog/writing-a-good-claude-md)
- [Stop Bloating Your CLAUDE.md: Progressive Disclosure (alexop.dev)](https://alexop.dev/posts/stop-bloating-your-claude-md-progressive-disclosure-ai-coding-tools/)
- [Conway's Law (Wikipedia)](https://en.wikipedia.org/wiki/Conway's_law)
- [Developers Are Victims Too: VS Code Extension Ecosystem (arXiv 2411.07479)](https://arxiv.org/html/2411.07479v1)
- [Supply Chain Risk in VS Code Extension Marketplaces (Wiz)](https://www.wiz.io/blog/supply-chain-risk-in-vscode-extension-marketplaces)
- [The xz Backdoor Was Just the Beginning (Linux Foundation / WebProNews)](https://www.webpronews.com/the-xz-backdoor-was-just-the-beginning-linux-foundation-sounds-the-alarm-on-social-engineering-attacks-targeting-open-source/)
- [Open Source and the Iceberg Theory (ACM Queue)](https://queue.acm.org/detail.cfm?id=3799738)
- [The Open Source Maintainer Burnout Crisis (Medium)](https://medium.com/@sohail_saifii/the-open-source-maintainer-burnout-crisis-nobody-s-fixing-5cf4b459a72b)
- [npm left-pad incident (Wikipedia)](https://en.wikipedia.org/wiki/Npm_left-pad_incident)
- [The Event Stream Debacle (TrackJS)](https://trackjs.com/blog/event-stream/)
- [event-stream, npm, and trust (LWN)](https://lwn.net/Articles/773121/)
- [Goodhart's law (Wikipedia)](https://en.wikipedia.org/wiki/Goodhart's_law)
- [Goodhart's Law in Software Engineering (Buttondown / Hillel Wayne)](https://buttondown.com/hillelwayne/archive/goodharts-law-in-software-engineering/)
- [CNCF Project Lifecycle and Process](https://contribute.cncf.io/projects/lifecycle/)
- [CNCF Maturity Ladder Analysis](https://timderzhavets.com/blog/cncf-project-maturity-ladder-when-to-bet-on-sandbox-vs/)
- [Monorepo vs Polyrepo (Nx monorepo.tools)](https://monorepo.tools/)
- [joelparkerhenderson/monorepo-vs-polyrepo (GitHub)](https://github.com/joelparkerhenderson/monorepo-vs-polyrepo)
