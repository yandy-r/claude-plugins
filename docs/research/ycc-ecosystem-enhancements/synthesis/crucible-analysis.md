# Crucible: Analysis of Competing Hypotheses (ACH)

**Analyst**: ach-analyst (Asymmetric Research Squad)
**Method**: Richards Heuer, _Psychology of Intelligence Analysis_, Ch. 8 — Analysis of Competing Hypotheses.
**Subject**: What SHOULD be added to the `ycc` ecosystem (networking, K8s, containers, virtualization, network security, cloud, vendor platforms), if anything?
**Date**: 2026-04-20
**Inputs**: 8 persona findings (historian, contrarian, analogist, systems-thinker, journalist, archaeologist, futurist, negative-space) + repo objective.

---

## Executive Summary

Two hypotheses survive disconfirmation: **H4** (3-5 workflow-shaped skills + supporting hooks, reject vendor matrix) and **H3** (hooks + validation scripts only, no new skills). **H1** (broad vendor matrix) is decisively eliminated by convergent evidence from 7/8 personas on hallucination, vendor-MCP competitive exclusion, and the 4× maintenance multiplier. **H2** (build nothing) is weakened by archaeologist + negative-space identification of concrete, documented workflow gaps that neither vendor tooling nor the `ycc` inventory closes. **H5** (pure composition / meta-skills) is directionally endorsed by systems-thinker as an LP #6 intervention but lacks a proven track record at this bundle size and leaves safety-primitive gaps unaddressed. **H6** (content-only pitfalls skills) fails the contrarian's core test: prose cannot fix LLM confabulation the way deterministic validators can. The discriminating question between H3 and H4 is whether the archaeological workflow artifacts (MOP, cook-and-diff, pre/post-check) count as **reasoning scaffolds needing a skill** or can be **encoded deterministically as scripts+hooks alone**.

---

## Hypotheses

Seven hypotheses generated; five are mutually exclusive primary strategies (H1-H5), one is a content-only subtype (H6), and one is a hybrid (H7) that is also scored to test whether the synthesis collapses the others.

### H1 — Broad Vendor Matrix (Coverage-First)

Build skills and agents across all seven domains: `ycc:cisco-iosxe`, `ycc:junos`, `ycc:fortinet`, `ycc:panos`, `ycc:k8s-day2`, `ycc:aws-ops`, `ycc:azure-ops`, `ycc:gcp-ops`, plus per-vendor virt/netsec skills. Each vendor gets first-class representation.

- **Proponents among personas**: none. (No persona advocates for this.)
- **Strawman owner**: a completionist reading of the objective that treats "the owner works in 7 domains" as "build 7 domain trees."
- **Implication if correct**: `ycc` becomes a multi-domain reference library with ~25-40 new artifacts, each 4×-replicated, ~100-160 generated files net.

### H2 — Zero New Artifacts (Archive-as-Is + Redirect)

Ship nothing. Document in README that `ycc` is a dev-workflow bundle, defer all infra work to vendor MCPs, vendor CLIs, and existing FOSS (Ansible, Nornir, Batfish, kubectl plugins, Crossplane, Terraform providers).

- **Proponents**: contrarian (strongest; argues 5/7 domains are net-negative). Partial support from systems-thinker (current inventory is correctly tuned at the policy layer; expansion risks B2 context-rot loop).
- **Implication if correct**: `ycc` stays at ~140 source artifacts; maintainer attention preserved; no new failure modes introduced; documented workflow gaps go unfilled.

### H3 — Hooks + Scripts Only (Safety Primitives)

Build **zero new skills or agents**; add a `ycc/hooks/` directory with 6-10 PreToolUse / PostToolUse hooks and supporting `_shared/scripts/` helpers (blast-radius, context-guard, wrong-cluster, secrets-scanner, change-window, cook-and-diff, copy-run-start guard, audit-log emitter). Everything is deterministic; nothing is prompt-level.

- **Proponents**: contrarian (explicitly argues "hooks >> skills for infra"); negative-space (calls the empty `hooks/` directory the "single clearest complementary absence"); archaeologist supports the determinism discipline (cook-the-output, `copy run start` guard); analogist's Gawande "communication checklist" maps to hooks.
- **Implication if correct**: `ycc` gains its safety layer; no descriptor bloat; skill count unchanged; the deterministic guardrails that all personas agree matter ship first.

### H4 — Workflow-Shaped Skills (3-5) + Hooks + Thin Agents

Build a **small number** (3-5) of vendor-agnostic, workflow-shaped skills: `ycc:network-change-review`, `ycc:mop` (Method of Procedure generator), `ycc:pre-post-check`, `ycc:config-drift`, `ycc:evidence-bundle`; ship the H3 hook set alongside; add **at most** 1-2 thin agents (e.g., `ycc:change-reviewer`). Explicitly reject per-vendor skills.

- **Proponents**: historian ("workflow-shaped, not vendor-shaped"); analogist (Remote-SSH analog, "keystone not body count", Gawande trio of skill+script+hook); archaeologist (P0 list: config-drift, MOP, pre/post-check); negative-space (workflow skills > vendor skills at 1/3 maintenance cost); futurist (universal spine: NL → IR → validate → plan → confirm → deploy → verify); journalist (the empty market niche is cross-vendor workflow synthesis; vendor MCPs already cover device-level).
- **Implication if correct**: ~4-6 new skills + 1-2 agents + hooks = ~8-12 new source artifacts (32-48 generated), well below the 70-90 skill tipping point the systems-thinker flags.

### H5 — Skills-of-Skills / Pure Composition

Build **one** router meta-skill (`ycc:infra-change` or `ycc:infra-route`) that dispatches to existing `ycc:plan` / `ycc:code-review` / `ycc:git-workflow` conditionally on repo signature (k8s manifests? Terraform? Cisco config?). Add meta-hooks only. Net-new leaf artifacts: 0-1.

- **Proponents**: systems-thinker explicitly proposes this as an LP #6 intervention ("one descriptor unlocks N latent workflows without N descriptors"). Tentative support from contrarian (closest to "vendor-router skill" steelman).
- **Implication if correct**: descriptor budget barely moves; leverage comes from reusing existing assets; unproven at this bundle size.

### H6 — Domain "Pitfalls" Reference Skills Only (Content-Only, No Scripts)

Build one narrow "LLM infra-pitfalls" skill modeled on TerraShark's approach: enumerate documented LLM failure patterns per domain (Terraform `count` vs `for_each`, Cisco-vs-Junos redistribution idioms, wrong `kubectl` context, PIX 8.3 ACL semantic flip). Pure prose guidance, no scripts, no hooks.

- **Proponents**: contrarian (explicitly proposes one such skill as their "defensible positive"); analogist partially (Gawande "judgment scaffold" half of the stack).
- **Implication if correct**: ~1 skill, minimal maintenance; tells Claude _how to think about_ specific failure modes; does not change runtime behavior deterministically.

### H7 — Hybrid (H3 + narrow slice of H4)

Build H3 hooks/scripts PLUS the archaeological P0 skills (`ycc:config-drift`, `ycc:mop`, `ycc:pre-post-check`) and reject the rest. Effectively: H4 minus `network-change-review` and `evidence-bundle`.

- **Proponents**: none explicitly; constructed to test whether archaeologist's tight list + contrarian's hooks is the actual stable equilibrium.
- **Implication if correct**: ~3 skills + hooks + scripts = ~5-8 new source artifacts. Most operationally grounded; least ambitious on IR/futurist dimensions.

---

## Evidence Catalog

Numbered evidence items extracted from persona findings. Each is tagged with source persona(s) and evidence quality (H/M/L).

| #   | Evidence                                                                                                                                                                                                                                                                                                                                                                                                                                   | Source persona(s)                                                                                | Quality                        |
| --- | ------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------ | ------------------------------------------------------------------------------------------------ | ------------------------------ |
| E1  | 30-year pattern: every tool that "wrapped the diff-review-apply loop" (RANCID, Oxidized, `ansible --check --diff`, `terraform plan`) survived; every tool that tried to replace the loop with a "platform" (onePK, TOSCA, pure OpenFlow) died.                                                                                                                                                                                             | historian                                                                                        | H                              |
| E2  | Single-maintainer ecosystems fail by **vertical expansion**, not solo maintenance per se. Tidelift: 46-58% maintainer burnout; top causes are issue management and doc maintenance, not coding. Booklore collapsed in 2026 after AI-assisted scope expansion under one maintainer. Kubernetes Ingress NGINX stopped shipping security patches March 2026 for the same reason.                                                              | historian, contrarian, systems-thinker                                                           | H                              |
| E3  | LLMs empirically confabulate vendor CLI syntax at rates that matter for production: GPT-4 confuses Cisco route-maps vs Junos routing policies; vendor manuals are 7,300+ pages (Huawei NE40E); IRAG benchmark: 97.74% syntax correctness _only_ with RAG over vendor manuals; LLM-alone ceiling ~85%.                                                                                                                                      | contrarian, negative-space                                                                       | H                              |
| E4  | Every major vendor is shipping or has shipped MCP servers: Palo Alto Cortex MCP (official, open beta), Juniper Junos MCP (official, with `block.cmd` safety regex), Cisco Network MCP Docker Suite (Cisco Switzerland, 7-10 servers), Fortinet community + AAIF membership, HashiCorp Terraform + Packer Agent Skills (official), AWS Cloud Control API MCP, Nautobot MCP (April 2026). Itential catalogs 56 production-ready MCP servers. | journalist, futurist, contrarian                                                                 | H                              |
| E5  | Context-rot is real and measurable: Anthropic's own reporting shows 5 MCP servers with 58 tools burn ~55K tokens before conversation; some setups use 134K tokens (half of Claude's window) on tool definitions alone. Vercel evals: skills not invoked in 56% of cases at scale.                                                                                                                                                          | contrarian, systems-thinker                                                                      | H                              |
| E6  | `ycc` currently ships 45 skills + 52 agents + 43 commands = ~140 source artifacts × 4 targets ≈ 560 generated files. 13 validators. 1 maintainer.                                                                                                                                                                                                                                                                                          | systems-thinker (primary); negative-space (inventory audit)                                      | H                              |
| E7  | Claude Code plugin ecosystem reviews (2026): "30 of 250 worth installing" (~12% keep rate); separate test found 4/11 worth keeping always (36%). Community consensus: run 2-3 plugins max.                                                                                                                                                                                                                                                 | journalist, contrarian                                                                           | M-H                            |
| E8  | Concrete documented workflow absences in `ycc` (not filled by vendor MCPs): no hooks directory at all (only a `hooks-workflow` skill that talks about them); no blast-radius labels on any command; no cluster-context guard; no MOP generator; no pre/post-check snapshot; no config-drift watcher with "cooked" diff; no audit/evidence bundle for SOX/HIPAA/PCI.                                                                        | negative-space (audit); archaeologist (forgotten wisdom list); contrarian (steelman concessions) | H                              |
| E9  | AWS Kiro incident (Oct 2025): AI bot with operator-level permissions and no peer review autonomously deleted-and-recreated prod, causing 13-hour Cost Explorer outage. AWS post-mortem: AI tools need **constrained permissions**, **mandatory peer review**, **gradual rollouts**. Amazon "90-day code safety reset" (March 2026) and Meta SEV1 agent incident reinforce the pattern.                                                     | contrarian, futurist                                                                             | H                              |
| E10 | `ycc` `hooks-workflow` skill exists but the repo ships **no installable hook artifacts**. This is the clearest single complementary absence — a published skill with no shipping scaffolding.                                                                                                                                                                                                                                              | negative-space                                                                                   | H                              |
| E11 | Research convergence on universal workflow shape: NL intent → typed IR → validate (Batfish/opa/kubeval) → plan → confirm → deploy → verify → rollback-ready. Xumi (arXiv:2508.17990), Clarify (HotNets 2025), NYU Firewall (Jan 2026), arXiv:2512.10789 (Dec 2025) — four independent tracks converged 2025.                                                                                                                               | futurist                                                                                         | H (peer-reviewed)              |
| E12 | Gartner: 25% of initial network configs done by GenAI by 2027 (up from <3% in 2024); 33% of business software includes agentic AI by 2028 (from <1% in 2024); "nearly all" network vendors embed AI/GenAI in management platforms by 2027.                                                                                                                                                                                                 | futurist                                                                                         | M (synthetic/aggregator)       |
| E13 | Ivan Pepelnjak critique (Packet Pushers TCG056, Aug 2025): "AI is the new SDN" — vendor hype cycle on repeat; "networks aren't automatable until they're _designed_ to be, tools come second." Convergent with Hightower ("zero-token architecture = bash + curl") and Majors ("AI solves this is theater").                                                                                                                               | contrarian, historian, futurist                                                                  | H (credentialed practitioners) |
| E14 | Network engineers are not developers; Puppet's pull-model + agent-based design died in networking because operators need push-based, low-ceremony tooling. Ansible won because of agentless SSH + YAML + no developer ceremony.                                                                                                                                                                                                            | historian, analogist                                                                             | H                              |
| E15 | Archaeological forgotten patterns still address 2026 failure modes that no modern tool covers: RANCID's "cook-the-output" discipline (strip volatile fields before diffing); MOP as artifact (Method of Procedure with explicit rollback commands); pre/post-check snapshotting; `copy run start` guard; change-window enforcement; flat-file inventory (`router.db`).                                                                     | archaeologist                                                                                    | H                              |
| E16 | Plugin ecosystem analogies converge on "fill empty niches, avoid competitive exclusion": VS Code Remote-SSH succeeded by filling one empty niche; Backstage maintainers publicly regret 15 GitHub plugins vs 1 comprehensive plugin; Terraform Registry uses three-tier quality model (Official/Verified/Community); Ansible Galaxy FQCN reserves reputation lanes.                                                                        | analogist                                                                                        | H                              |
| E17 | Systems-thinker estimates tipping point at 70-90 skills before B2 (context-pollution loop) becomes dominant. Current ycc: 45 skills. H1 adds 25-40 skills, crossing the threshold. H4 adds 4-6 skills, stays well under.                                                                                                                                                                                                                   | systems-thinker                                                                                  | M (analyst estimate)           |
| E18 | Safety patterns in shipping vendor MCP servers: Juniper `block.cmd` regex blocker; vlanviking `PANOS_READONLY`; candidate-config + explicit commit gates; OS-keychain token storage; strict XPath validation. **Write-path is where every serious MCP is deliberately slow**.                                                                                                                                                              | journalist, futurist                                                                             | H                              |
| E19 | The "2-3 plugins max" consensus (composio, self.md, DEV) combined with community reviewer data (12-36% keep rate) validates the "lean, high-value" bundle posture.                                                                                                                                                                                                                                                                         | journalist, contrarian                                                                           | M-H                            |
| E20 | Completionism is explicitly listed as a bias to guard against in the repo's own objective (bias #3); maintenance-cost blindness is bias #5. The project CLAUDE.md already gates additions via `bundle-author` + `compatibility-audit` + scope guardrails.                                                                                                                                                                                  | objective.md + systems-thinker                                                                   | H (repo self-disclosure)       |
| E21 | Vendor-specific tooling half-life is 5-10 years (Juniper SLAX, Cisco onePK dead at 1-2 years). Open standards (NETCONF, YANG, OpenConfig) have 20+ year lives. Vendor MCPs are the new vendor SDKs and inherit the same lifecycle risk.                                                                                                                                                                                                    | historian, futurist                                                                              | H                              |
| E22 | Air-gapped / regulated / OT markets cannot use cloud inference; Tabnine owns that mindshare. No `ycc` skill declares `requires-network: false`. This is a segmentation issue, not a skill issue.                                                                                                                                                                                                                                           | negative-space                                                                                   | M-H                            |
| E23 | The 4× compat multiplier is real: every source artifact is generated into Claude + Cursor + Codex + opencode. Cursor doesn't consume `.md` commands natively; Codex has no slash-command layer; opencode has distinct hook semantics. Every new artifact = 4× generator/validator/doc cost.                                                                                                                                                | systems-thinker, contrarian, negative-space                                                      | H (repo structure)             |
| E24 | The empty market niche the journalist identified: cross-vendor workflow synthesis ("change-review + diff + blast-radius + rollback-plan" wrapping existing MCPs). "No vendor ships this. Community doesn't either."                                                                                                                                                                                                                        | journalist                                                                                       | M-H                            |
| E25 | Adversarial telemetry is a concrete new attack class (AIOpsDoom arXiv:2508.06394, defense AIOpsShield): adversaries manipulate telemetry to steer agent decisions. Any skill consuming observability data must assume inputs may be attacker-controlled.                                                                                                                                                                                   | futurist                                                                                         | H (peer-reviewed)              |
| E26 | Claude Code's auto-approve rate rises from ~20% (<50 sessions) to 40%+ (750+ sessions) — trust calibration is empirically earned over time. High-profile incidents (Kiro, Meta SEV1) can force regression.                                                                                                                                                                                                                                 | futurist                                                                                         | H (first-party data)           |
| E27 | Reinforcing loop R1 (author-uses-skill → feedback → virtuous loop) weakens when the skill is outside the maintainer's daily workflow. Domains the owner touches less frequently will have invisible drift between releases.                                                                                                                                                                                                                | systems-thinker                                                                                  | M                              |
| E28 | Junior network engineer pipeline is under-served: `ycc` has no coach-mode flag; AI tools optimize for senior output not junior training; 54% of eng leaders hiring fewer juniors.                                                                                                                                                                                                                                                          | negative-space                                                                                   | M                              |
| E29 | "Every hook is 4 hooks" in `ycc`'s target matrix: Cursor/Codex/opencode each have different hook semantics → a single hook's cost is really 4×, plus validator updates.                                                                                                                                                                                                                                                                    | systems-thinker, contrarian                                                                      | H                              |
| E30 | The universal safety artifact across all persona positive-cases: wrong-cluster/wrong-context gate as a PreToolUse hook. Every safety plugin reviewed in the ecosystem (`safety-net`, `nah`, `Sagart-cactus`, Kubesafe) is a hook, not a skill.                                                                                                                                                                                             | negative-space, contrarian, analogist                                                            | H                              |

---

## Evidence × Hypotheses Matrix

Legend: **C** = consistent (supports); **I** = inconsistent (refutes); **N** = neutral / doesn't discriminate. Quality tags come from the evidence catalog.

| #   | Evidence (summary)                                             | Q   | H1 (Vendor matrix)           | H2 (Zero build)    | H3 (Hooks only)              | H4 (Workflow skills + hooks)         | H5 (Pure composition)                   | H6 (Pitfalls only)                       | H7 (Hybrid) |
| --- | -------------------------------------------------------------- | --- | ---------------------------- | ------------------ | ---------------------------- | ------------------------------------ | --------------------------------------- | ---------------------------------------- | ----------- |
| E1  | Loop wins, platforms die                                       | H   | I                            | N                  | C                            | C                                    | C                                       | N                                        | C           |
| E2  | Single-maintainer scope expansion fails                        | H   | I                            | C                  | C                            | C                                    | C                                       | C                                        | C           |
| E3  | LLM vendor-CLI confabulation (85% ceiling)                     | H   | I                            | N                  | C                            | C                                    | N                                       | C                                        | C           |
| E4  | Every vendor ships an MCP; 56 in catalog                       | H   | I                            | C                  | C                            | C                                    | C                                       | N                                        | C           |
| E5  | Context-rot at 55-134K token budgets                           | H   | I                            | C                  | C                            | C (if ≤5 skills)                     | C                                       | C                                        | C           |
| E6  | ycc: 140 sources × 4 targets = 560 files                       | H   | I                            | C                  | C                            | C                                    | C                                       | C                                        | C           |
| E7  | "30/250 worth installing" (12-36% keep)                        | M-H | I                            | C                  | C                            | C                                    | C                                       | C                                        | C           |
| E8  | Concrete workflow gaps (MOP, drift, pre/post, hooks)           | H   | N                            | **I**              | C (partial)                  | **C** (full)                         | I (composition alone doesn't fill them) | I (prose alone doesn't fill)             | C           |
| E9  | Kiro / Meta SEV1: guardrails > agents                          | H   | I                            | N                  | **C**                        | C                                    | N                                       | I                                        | C           |
| E10 | Empty `ycc/hooks/` is biggest complementary absence            | H   | N                            | **I**              | **C**                        | C                                    | N                                       | I                                        | C           |
| E11 | NL → IR → validate → deploy → verify converged                 | H   | N                            | I                  | N                            | **C** (spine-shaped)                 | C                                       | N                                        | C (partial) |
| E12 | Gartner: 25% GenAI configs by 2027                             | M   | C                            | I                  | N                            | C                                    | C                                       | N                                        | N           |
| E13 | Pepelnjak / Hightower / Majors: fundamentals, not prompts      | H   | **I**                        | C                  | C                            | C                                    | C                                       | I (prose is exactly what they criticize) | C           |
| E14 | Net engineers ≠ devs; ceremony kills adoption                  | H   | I                            | N                  | C                            | C (if workflow-shaped)               | N                                       | I                                        | C           |
| E15 | Archaeological patterns still relevant (RANCID, MOP, pre/post) | H   | N                            | I                  | C (scripts can encode most)  | **C** (skill = judgment layer)       | I                                       | N                                        | **C**       |
| E16 | Fill empty niches; Backstage regrets 15 plugins                | H   | **I**                        | N                  | C                            | **C**                                | C                                       | C                                        | C           |
| E17 | 70-90 skill tipping point; H1 crosses it                       | M   | **I**                        | C                  | C                            | C                                    | C                                       | C                                        | C           |
| E18 | Write-path safety patterns in vendor MCPs                      | H   | N                            | N                  | **C** (hook IS this pattern) | C                                    | N                                       | I                                        | C           |
| E19 | "2-3 plugins max" keep rate                                    | M-H | I                            | C                  | C                            | C                                    | C                                       | C                                        | C           |
| E20 | Completionism + maintenance-blindness are flagged biases       | H   | **I**                        | C                  | C                            | C                                    | C                                       | C                                        | C           |
| E21 | Vendor tooling half-life 5-10y; standards 20+y                 | H   | **I**                        | N                  | N                            | C (vendor-agnostic)                  | C                                       | N                                        | C           |
| E22 | Air-gap / OT segments can't use cloud inference                | M-H | I (prose still sends tokens) | N                  | C (scripts run locally)      | C (skills can gate)                  | N                                       | N                                        | C           |
| E23 | 4× compat multiplier cost                                      | H   | **I**                        | C                  | C (hooks have E29 cost)      | C                                    | C                                       | C                                        | C           |
| E24 | Empty niche: cross-vendor workflow synthesis                   | M-H | I (duplicates MCPs)          | I (gap stays open) | N (partial)                  | **C** (direct hit)                   | C (if router routes to MCPs)            | N                                        | C (partial) |
| E25 | AIOpsDoom: adversarial telemetry                               | H   | N                            | N                  | C (sanitizer helper)         | C (sanitizer + skill)                | N                                       | N                                        | C           |
| E26 | Auto-approve rises with trust; incidents cause regression      | H   | I                            | N                  | C                            | C                                    | N                                       | N                                        | C           |
| E27 | R1 weakens outside maintainer's daily flow                     | M   | **I**                        | C                  | C                            | C                                    | C                                       | C                                        | C           |
| E28 | Junior pipeline under-served                                   | M   | N                            | I                  | N                            | C (coach-mode on workflow skills)    | N                                       | C                                        | C           |
| E29 | Every hook is 4 hooks (cross-target tax)                       | H   | I                            | C                  | **I** (partial)              | I (partial, but fewer)               | C                                       | C                                        | I (partial) |
| E30 | All safety plugins in ecosystem are HOOKS, not skills          | H   | **I**                        | N                  | **C**                        | C (hooks are still the safety layer) | N                                       | **I** (pitfalls-skill is not a hook)     | C           |

**C count / I count summary**:

| Hypothesis          | C   | I      | Net (C-I) | Key disconfirmers                                                                         |
| ------------------- | --- | ------ | --------- | ----------------------------------------------------------------------------------------- |
| H1 Vendor matrix    | 1   | **22** | **-21**   | E1, E2, E3, E4, E5, E6, E7, E13, E16, E17, E20, E21, E23, E27, E30 (all H-quality)        |
| H2 Zero build       | 11  | 6      | +5        | E8, E10, E11, E12, E15, E24, E28                                                          |
| H3 Hooks only       | 19  | 2      | +17       | E8 (partial), E11 (doesn't address IR/workflow shape)                                     |
| H4 Workflow + hooks | 22  | 1      | **+21**   | E29 (partial — still bears hook multiplier)                                               |
| H5 Pure composition | 13  | 5      | +8        | E8, E15, E18 (composition doesn't fill gaps that need new artifacts)                      |
| H6 Pitfalls only    | 10  | 8      | +2        | E13 (prose is what critics reject), E9, E18, E30 (safety is hook-shaped not prose-shaped) |
| H7 Hybrid           | 21  | 1      | +20       | E29 (partial)                                                                             |

---

## Critical Disconfirming Evidence

Per Heuer, disconfirmation is the analytical lever. Evidence that _kills_ a hypothesis is more decisive than evidence that supports multiple.

### H1 (Vendor matrix) — ELIMINATED

The hypothesis faces disconfirming evidence from **every** domain of the persona mandate:

- **E3** (LLM confabulation): vendor-CLI hallucination is _documented_, not hypothetical, and a prose skill does not add the RAG-over-vendor-manuals layer that produces 97.74% accuracy. A vendor-tree of skills inherits the 85% ceiling and masks it behind plausible syntax.
- **E4** (MCP saturation): the vendors themselves are shipping the competing artifact. A `ycc:cisco-iosxe` skill in 2026-Q2 competes against Juniper's official Junos MCP, Palo Alto's Cortex MCP, Cisco's Network MCP Docker Suite. Competitive exclusion (analogist).
- **E21** (vendor half-life): vendor CLIs rebrand every 5-10 years. Per-vendor skills inherit the rebrand risk.
- **E17 + E5 + E23** (scale math): adding 25-40 artifacts × 4 targets crosses the 70-90 tipping point, raises descriptor-prompt floor to ~45K tokens, and demands 4× generator/validator maintenance that one maintainer cannot sustain (E2 Booklore, Ingress NGINX).
- **E13** (credentialed practitioner consensus): Pepelnjak, Hightower, and Majors converge against exactly this pattern.
- **E27** (R1 weakens): the maintainer's feedback loop doesn't fire on domains they touch infrequently, so drift grows silently between releases.

**No persona advocates H1. No evidence supports it directly.** It is the strawman the objective explicitly warns against (biases #3 and #5 in objective.md). **Eliminated with high confidence.**

### H6 (Pitfalls-only skill) — WEAKENED, NOT FULLY ELIMINATED

A single "LLM infra-pitfalls" skill has one strong proponent (contrarian's steelman) and the weakest disconfirmation profile among near-eliminated hypotheses. But:

- **E13 + E30**: Pepelnjak/Hightower/Majors reject "AI-for-ops-as-prompt" exactly. A prose-only skill _is_ the artifact they criticize. Every safety plugin in the ecosystem is a hook, not a prose doc.
- **E9 + E18**: real production incidents (Kiro, Meta SEV1) and real vendor MCP safety (`block.cmd`, `PANOS_READONLY`) are deterministic. Prose cannot produce the deterministic behavior that is empirically what matters.
- **E3 partial C**: prose can raise the floor slightly on known hallucination patterns, but cannot match RAG+validation.

**H6 survives as a minor supporting artifact, not a primary strategy.** It is a candidate sub-component of H4 (the "judgment" half of the Gawande stack per analogist), not a standalone answer. Eliminated as primary.

### H5 (Pure composition) — WEAKENED

H5 has conceptual appeal (systems-thinker's LP #6 leverage play) but fails specific disconfirming checks:

- **E8 + E10 + E15**: the documented workflow gaps (MOP artifact, cook-and-diff drift watcher, pre/post-check snapshot, empty hooks directory) are **primitives that do not currently exist in ycc**. Composition cannot invoke skills that aren't there. Pure composition leaves the concrete gaps unfilled.
- **E18 + E30**: the safety artifacts the ecosystem converges on (write-path gates, wrong-context guards) are hook-shaped new primitives, not existing-skill compositions.

H5 is therefore **a valid architectural principle inside H4** (the workflow skills should themselves be composition-heavy when possible) but not an adequate primary strategy. Weakened; folded into H4.

### H2 (Zero build) — WEAKENED

H2 is the honest null hypothesis and the contrarian's primary position. It survives most scale/maintenance disconfirmation. But:

- **E8, E10, E15, E24**: concrete workflow gaps _documented in direct inventory audits_ (negative-space, archaeologist) are not addressable by vendor MCPs because the gap is **cross-vendor workflow synthesis** that no vendor has an incentive to ship.
- **E9 + E30**: shipping zero hook artifacts means the documented AI-autonomy incidents (Kiro, SEV1) continue to threaten `ycc` users with no first-party guardrails, despite hooks being unanimously identified as the right artifact class.
- **E11**: the converged NL→IR→validate→deploy→verify workflow spine is an active market convergence — refusing to ship anything forfeits this position entirely.

H2's strongest argument (the maintainer tax under 4× multiplier) is real, but **E29** (every hook is 4 hooks) applies identically to H3/H4/H7, so the argument doesn't distinguish H2 from the narrow-build hypotheses. H2 survives as a fallback but is not evidentially dominant.

### H3 (Hooks only) vs H4 (Workflow + hooks)

These are the two serious contenders. The discriminating question:

**Does ycc need skill-shaped artifacts for reasoning scaffolds (MOP authoring, change-review narrative, evidence-bundle structuring), or can those be encoded as scripts+templates triggered by hooks?**

Evidence bearing on this:

- **E15** (archaeologist): MOP generation, pre/post-check design, config-drift cooking all require **per-vendor regex knowledge + judgment about volatile fields + narrative generation**. A pure script can do the mechanical part; a skill is needed for the judgment layer.
- **E11** (futurist): the NL→IR→validate spine assumes an LLM-driven front end (NL intent → IR). That front end is skill-shaped.
- **E24** (journalist): "cross-vendor workflow synthesis" is prose-plus-action, not pure action.
- **Analogist's Gawande trio** (E15 supports): the pattern is skill (judgment) + script (determinism) + hook (communication checklist). Not one of the three — all three layered.

**H4 wins the H3-vs-H4 discrimination on these specific evidence items.** H3 alone leaves the reasoning-scaffold gap open; H4 layers skill + script + hook as the analogist/archaeologist-recommended pattern.

### H7 (Hybrid) — Competitive with H4

H7 = H3 hooks + archaeological P0 skills (`config-drift`, `mop`, `pre-post-check`), rejecting `network-change-review` and `evidence-bundle`. Its C/I profile is nearly identical to H4 (+20 vs +21) and it has one advantage: **tighter scope** (3 skills vs 4-5), better aligned to the "use-3-times-in-60-days" CNCF-adoption test (analogist).

The discriminator between H4 and H7 is whether `network-change-review` (the futurist's universal spine skill) is **real and needed today** or a premature abstraction. Futurist's evidence (E11) is forward-looking; archaeologist's evidence (E15) is backward-looking and field-proven. H7 ships only the field-proven artifacts.

---

## Hypothesis Survival Analysis

| Hypothesis          | Status                                            | Primary reason                                                                  |
| ------------------- | ------------------------------------------------- | ------------------------------------------------------------------------------- |
| H1 Vendor matrix    | **Eliminated**                                    | -21 net; disconfirmed by every persona, every evidence class                    |
| H6 Pitfalls-only    | **Eliminated as primary** (survives as component) | Prose cannot do what critics demand; safety is hook-shaped not prose-shaped     |
| H5 Pure composition | **Weakened to principle** (not primary)           | Cannot invoke primitives that don't exist; gaps demand new artifacts            |
| H2 Zero build       | **Weakened to fallback**                          | Real gaps remain unaddressed; saving hook tax doesn't distinguish it from H3/H4 |
| H3 Hooks-only       | **Surviving (strong)**                            | +17 net; correctly identifies the deterministic safety layer                    |
| H4 Workflow + hooks | **Surviving (strongest)**                         | +21 net; closes all documented gaps; layers skill+script+hook per analogist     |
| H7 Hybrid           | **Surviving (tight)**                             | +20 net; most operationally proven; narrower ambition                           |

**Surviving hypotheses: H3, H4, H7** (H4 and H7 are near-identical except for scope).

---

## Relative Strength Assessment

### Most viable → least

1. **H4 — Workflow-shaped skills + hooks** (Viability: **High**)
   - Highest +C-I score (+21).
   - Endorsed by 6/8 personas (historian, analogist, archaeologist, negative-space, futurist, journalist).
   - Directly closes concrete gaps (MOP, drift, pre/post, hooks, evidence).
   - Honors the maintenance budget: 4-6 skills + hooks is below the 70-90 tipping point.
   - Consistent with the vendor-MCP trajectory (workflow layer sits _above_ MCPs, doesn't duplicate them).
   - Matches the converged research spine (NL→IR→validate→deploy→verify).

2. **H7 — Hybrid (H3 + archaeological P0 skills)** (Viability: **High-Medium**)
   - Near-identical score to H4 (+20).
   - Ships only field-proven artifacts (RANCID-lineage), avoids the futurist's forward-looking skill.
   - Lower risk if the owner's domain weighting is uncertain (E27).
   - Leaves a gap on the NL→IR spine (E11) that the market is actively filling.

3. **H3 — Hooks only** (Viability: **Medium**)
   - Correctly identifies the deterministic safety layer (+17).
   - Fails to close the reasoning-scaffold gap (MOP, change-review, evidence-bundle).
   - Strongest on "do no harm" grounds; weakest on "unlock value" grounds.

4. **H2 — Zero build** (Viability: **Low-Medium**)
   - Defensible as a fallback if the owner's infra use is lower than stated.
   - Leaves documented workflow gaps open indefinitely.
   - Forfeits the cross-vendor workflow-synthesis niche.

5. **H5 — Pure composition** (Viability: **Low as primary; High as principle**)
   - Architecturally attractive (LP #6 leverage).
   - Cannot invoke primitives that don't exist.
   - Valid internal design principle for H4's skills.

6. **H6 — Pitfalls-only** (Viability: **Low as primary; Medium as component**)
   - Valid as a supporting artifact under H4.
   - Fails as standalone: critics explicitly reject prose-as-safety.

7. **H1 — Vendor matrix** (Viability: **Very Low**)
   - Eliminated.

### Primary recommendation

**H4 is the lead hypothesis**, with H7 as the tighter fallback if the owner's CNCF-adoption test (analogist: "used 3+ times in last 60 days") fails for `network-change-review` and `evidence-bundle`. H3 hooks ship as a prerequisite layer under both.

---

## Discriminating Evidence Needed

To confidently choose between H4 and H7:

1. **Usage-frequency audit** (analogist's CNCF-adoption test): Has the maintainer personally run a "network-change-review"-shaped workflow (diff + blast-radius + rollback + evidence) in the last 60-90 days, on real work? If ≥3 times, ship it (H4). If <3, defer (H7).
2. **Maintainer intent on evidence-bundle**: Is SOX/HIPAA/PCI-shaped audit evidence a live need in the maintainer's work, or an imagined one? If live, ship it (H4). If imagined, cut it (H7).
3. **Vendor-MCP maturity probe**: By 2026-Q3, how many vendor MCPs in the owner's actual working stack have first-party support? If >50% of relevant vendors ship official MCPs, `ycc:network-change-review` must be explicitly orchestration-over-MCP, not CLI-parsing (shapes implementation, doesn't change H4-vs-H7 directly).

To confidently discriminate between H4 and H2 (if the owner is considering walking away):

4. **Personal workflow count**: How many of archaeologist's P0 list (`config-drift`, `mop`, `pre-post-check`) has the owner hand-coded or pasted from Stack Overflow in the last quarter? Each hit is evidence for H4 over H2.
5. **4×-target cost reality check**: Time one hook end-to-end across 4 targets (author + validate + document). If >8 hours, H4 faces a real budget problem and H3 becomes relatively more attractive.

---

## Assumptions Challenged

The ACH surfaced three assumptions that run through the persona findings and deserve explicit challenge:

1. **"The owner actually works across all 7 stated domains with equal frequency."** The objective lists 7 domains but the R1 loop (systems-thinker) only fires on domains the owner touches often. If the owner's actual month-to-month weighting is 60/30/10 (say: dev-adjacent infra / networking-deep / everything else), the domain-expansion case is weaker than it looks and H7 becomes more attractive than H4.

2. **"Vendor MCPs will be broadly adopted and maintained by 2027."** This is the futurist's base case and the contrarian's primary reason to reject vendor skills. If vendor MCPs stall (onePK-style lifecycle risk per E21), then _some_ of the H1 argument returns. Counter-evidence (E4): every major vendor has shipped at least one MCP in 2026-H1; the trajectory is well-established. I assign this assumption **high confidence** (≥0.8).

3. **"Downstream user mix is primarily the owner."** The systems-thinker flagged this explicitly as an unknown. If `ycc` has a real external audience, H4's cross-vendor workflow skills serve many users at multiplicative leverage. If it is primarily the owner's personal toolkit, H7's tighter scope is more honest. **Direct resolution**: R2 (brand/adoption loop) is not currently dominant → treat as primarily the owner's tool → H7 and H4 are both defensible; H4's additional skill (`network-change-review`) needs the CNCF-adoption test to pass.

---

## Key Insights

1. **H1 is disconfirmed by every evidence class available** (peer-reviewed, practitioner, vendor self-report, repo-structural). No persona advocates for it. The objective's own bias list flagged it preemptively. The unanimity is itself a signal that the "completionist vendor-matrix" framing is a strawman to beat, not a live proposal.

2. **The safety-primitive layer (hooks) is where every persona converges.** Contrarian argues hooks-only; analogist's Gawande model includes hooks; negative-space calls the empty hooks directory the single clearest gap; futurist lists blast-radius hooks as a P0 bet; archaeologist's `copy run start` guard is a hook; systems-thinker explicitly notes every safety plugin reviewed is a hook. **Hooks are the stable intersection point across all surviving hypotheses.** Any ship plan that does not ship hooks first is weaker than one that does.

3. **The disagreement between contrarian and archaeologist is the crux.** Contrarian says "skills are prompts; prompts don't fix infra"; archaeologist says "old disciplines (MOP, cook-and-diff, pre/post-check) are exactly skill-shaped judgment layers Claude does well." Both are right about different layers. The resolution is the analogist's Gawande trio: hooks + scripts + skills, layered. H4 is this resolution made concrete.

4. **H5 (pure composition) fails the "primitives don't exist" test** but survives as an internal design principle. Any H4 skill that _can_ orchestrate existing `ycc:plan` / `ycc:code-review` / `ycc:git-workflow` should do so rather than reimplementing.

5. **H7 is H4's tighter fallback, not a distinct strategy.** The discriminator is entirely whether `network-change-review` and `evidence-bundle` pass the personal-use test. If they don't, `ycc` still gets 85% of H4's value by shipping just the archaeological P0 list + hooks.

6. **The cross-persona synthesis lands on ~4-6 new source artifacts + a hooks directory.** That is strikingly narrow for an expansion question, and it aligns with every scaling constraint flagged (E17, E23, E29, E6). **The expansion is small because the bundle is already dense.**

7. **The futurist's "universal spine" (NL → IR → validate → plan → confirm → deploy → verify) is the implementation shape for H4's workflow skills**, not a separate hypothesis. Any `network-change-review` skill built today should conform to this shape so it absorbs vendor-MCP integration and digital-twin validation over 2027-2028 without rewrite.

8. **Eight of eight personas implicitly or explicitly reject per-vendor skills.** That level of unanimity is rare and load-bearing.

---

## Methodology Notes

- **Hypothesis generation**: started from the six candidates provided in the task brief, added H7 (hybrid) after reading archaeologist + contrarian to test whether the stable equilibrium is narrower than H4. Rejected an eighth "build a separate ycc-netops sibling plugin" candidate as dominated by H4 (analogist: monorepo wins at single-maintainer scale per E14/E16).
- **Evidence extraction**: 30 evidence items across 8 personas + repo objective. Items are numbered for cross-matrix traceability. Quality tags reflect source class (peer-reviewed > vendor self-report > practitioner blog > synthetic aggregator).
- **Scoring**: the C/I matrix is analyst-applied per Heuer. Neutral items were scored N; ambiguous items were scored _per hypothesis interpretation_ (e.g., E24 is C for H4 directly, N-partial for H3).
- **Disconfirmation focus (Heuer's core)**: elimination is by refutation, not confirmation. H1 was eliminated by 15 H-quality disconfirmers across 7 personas; H6 by the internal contradiction that the critics it's modeled on reject prose-as-safety; H5 by the "primitives don't exist" existence check.
- **Contradictions preserved**: contrarian's "hooks, not skills" vs. archaeologist's "MOP needs judgment" is _not smoothed_; it is exploited as the H3 vs H4 discriminator. Futurist's forward-looking evidence is _not blended with_ archaeologist's backward-looking evidence; they discriminate H4 vs H7.
- **Limits**: I did not generate new evidence via searches (that was persona work). The analysis is bounded by what the 8 personas gathered. The absence of a usage-frequency audit (Discriminating Evidence #1) is the single biggest knowledge gap and the reason H4 is not cleanly preferred over H7.

---

## Confidence Assessment

| Claim                                        | Confidence      | Basis                                                                   |
| -------------------------------------------- | --------------- | ----------------------------------------------------------------------- |
| H1 is eliminated                             | **Very High**   | 15 H-quality disconfirmers; unanimous persona rejection; repo bias list |
| H4 is the leading primary strategy           | **High**        | +21 net score; 6/8 persona endorsement; scaling math holds              |
| H7 is a viable tight fallback to H4          | **High**        | +20 net; survives every disconfirmation H4 survives                     |
| H3 hooks are a prerequisite under H4/H7      | **Very High**   | Cross-persona convergence on hooks as the safety layer                  |
| H2 is a defensible fallback only             | **Medium-High** | Real scale cost, but leaves documented gaps open                        |
| H5 is weakened to internal principle         | **High**        | Cannot invoke non-existent primitives                                   |
| H6 is weakened to sub-component              | **High**        | Critics' own logic rejects prose-as-safety                              |
| The 70-90 skill tipping point is real        | **Medium**      | Analyst estimate (E17); shape robust, exact number is not               |
| The owner's domain weighting                 | **Unknown**     | Discriminating evidence #1; gap documented                              |
| Vendor-MCP saturation will hold through 2027 | **High (0.8)**  | E4 + E12 + E21 convergence                                              |

**Overall confidence in "H4 or H7 with H3 hook layer is correct"**: **High**. Overall confidence in choosing H4 over H7 specifically: **Medium** (depends on the usage-frequency audit).

---

_End of crucible analysis._
