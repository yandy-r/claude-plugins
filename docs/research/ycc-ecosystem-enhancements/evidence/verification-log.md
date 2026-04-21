# Evidence Verification Log

**Method**: Cross-persona triangulation + selective spot-checks. Primary sources
(vendor docs, official announcements, CNCF/Anthropic blog posts) cited in the
persona findings were relied on without re-fetching; high-impact contested claims
are flagged below for follow-up.

---

## High-Confidence Findings (multi-persona triangulation)

### F1. Vendor MCP servers exist and are becoming substrate in 2025-2026

- **Claimed by**: Journalist (primary, with dates), Contrarian (critical framing),
  Futurist (trajectory framing), Analogist (structural framing).
- **Sources cited**: Anthropic MCP announcement (Nov 2024), Palo Alto Cortex MCP
  (2025), Nautobot MCP 3.1 (April 14-15 2026), Itential MCP catalog (2026),
  Cisco/Juniper MCP exposure (2025-2026).
- **Verification status**: Confirmed via four personas with overlapping evidence.
- **Confidence**: High
- **Implication for `ycc`**: Duplicating a vendor MCP in a `ycc` skill is
  net-negative — use them as callable substrates, don't re-implement.

### F2. Safety/audit primitives (hooks, blast-radius, rollback, provenance) are the

conspicuously empty niche

- **Claimed by**: Negative-space (primary — no `hooks/` dir in ycc; no blast-radius
  labels), Contrarian (hooks are deterministic where skills are probabilistic),
  Archaeologist (RANCID/MOP/pre-check patterns all revolve around safety),
  Futurist (blast-radius guardrails are 2027 table stakes), Analogist
  (Gawande checklist + judgment layering).
- **Verification**: Cross-verified by 5 of 8 personas with independent reasoning.
- **Confidence**: High
- **Implication**: A `hooks/` layer + a small set of safety-shaped skills is the
  single highest-value intervention.

### F3. Workflow-shaped skills beat vendor-shaped skills (per-vendor matrix is a

graveyard pattern)

- **Claimed by**: Historian (Cisco onePK / SLAX / Opsware graveyard), Contrarian
  (vendor CLI hallucination rates), Analogist (Terraform Registry Official tier
  pattern), Futurist ("vendor-skins become dead weight once MCPs ship").
- **Verification**: 4-persona convergence with historical pattern support.
- **Confidence**: High
- **Implication**: Reject the "Cisco/Fortinet/Juniper/Palo Alto each gets its own
  skill" impulse. Build one `network-change-review` workflow that calls whichever
  vendor MCP/CLI is available.

### F4. `ycc` is near a context-rot tipping point (~70-90 artifacts)

- **Claimed by**: Systems-thinker (primary, with specific threshold estimate),
  Historian (solo-maintainer burnout 46-58% rate), Contrarian (maintainer cost
  critique).
- **Verification**: Systems-thinker grounded in current inventory count (~45 skills
  - ~45 agents + ~40 commands); historian backed by OSS maintainer burnout surveys.
- **Confidence**: Medium-High (threshold is an educated estimate, not a measurement)
- **Implication**: Net additions must be small (3-6) and high-signal. Compose over
  expand. A sunset rule is needed.

### F5. Owner actually reaches for network/infra work often enough to justify some

investment (but weighted toward non-vendor workflow helpers)

- **Claimed by**: User brief (self-reported), Negative-space (silent stakeholder
  category), Archaeologist (revival candidates map to real pre-cloud disciplines).
- **Verification**: Self-reported — not directly verifiable.
- **Confidence**: Medium (self-report only)
- **Implication**: Use a "3+ uses in 60 days" personal-use test before promoting
  a prototype to first-class `ycc` artifact.

---

## Medium-Confidence Findings

### F6. AWS Kiro 13-hour outage (contrarian's deterministic-vs-probabilistic exemplar)

- **Claimed by**: Contrarian
- **Verification status**: Partial — claim matches publicly reported AWS Kiro GA
  issues in late 2025 / early 2026, but exact 13-hour duration not double-sourced.
- **Confidence**: Medium
- **Notes**: Even if the specific hours are imprecise, the principle (AWS had a
  significant Kiro availability incident; deterministic safeguards would have
  helped) is not contested.

### F7. Ingress-NGINX maintainer burnout as solo-maintainer-expansion cautionary tale

- **Claimed by**: Historian, Contrarian
- **Verification status**: Directionally consistent with CNCF maintainer retention
  data and public Ingress-NGINX discussions, but the specific 46-58% number is an
  aggregate across multiple OSS surveys, not a single cite.
- **Confidence**: Medium
- **Notes**: Aggregate trend well-supported; specific percentage should be framed
  as "roughly half" rather than a precise figure in the final report.

### F8. MCP becoming Linux-Foundation-adjacent standard (AAIF, Dec 2025)

- **Claimed by**: Journalist
- **Verification status**: Anthropic MCP is on a standardization trajectory; exact
  AAIF/Linux Foundation partnership details vary by source.
- **Confidence**: Medium
- **Notes**: Substance (MCP is becoming de-facto standard) is uncontested. Exact
  governance structure details in final report should be qualified.

---

## Contradictions Requiring Resolution

### C1. Ship dosage — "3-4 artifacts" (contrarian) vs. "10-15 candidates" (negative-space)

- **Position A** (Contrarian): 3-4 artifacts maximum; all hooks + one pitfalls skill
- **Position B** (Negative-space): 15-candidate punch list, 6 in P0/P1 tier
- **Evidence for A**: Maintainer burnout literature; vendor-MCP duplication risk
- **Evidence for B**: Concrete workflow-absence list with specific failure modes
- **Resolution**: Contradiction-mapper classifies this as a **dosage, not
  direction** disagreement. Both agree on shape (workflow + safety, not vendor).
  The ACH analyst eliminates this tension by adopting H4 (4-6 artifacts) as the
  midpoint.

### C2. Temporal framing — archaeology-revival (archaeologist) vs. MCP-native future

(futurist)

- **Position A**: Revive RANCID-era patterns (diff-archive-rollback) as Claude skills.
- **Position B**: Assume MCP substrate; skills should be MCP-client orchestrators.
- **Resolution**: Not actually a contradiction. The diff-archive-rollback pattern
  maps cleanly onto an MCP-native implementation — MCP is the transport, the
  discipline is the content. Both are compatible.

### C3. Tipping-point warning (systems-thinker) vs. specific build lists (negative-space, archaeologist, futurist)

- **Position A** (Systems-thinker): Bundle is approaching fragility cliff.
- **Position B** (Negative-space et al.): Here are 15 specific useful additions.
- **Resolution**: Scale-of-analysis difference. The tipping-point warning is a
  **constraint**, not a **blocker**. It budgets the expansion at 3-6 net-new
  artifacts, not zero. Specific build lists are pre-filter inputs to that budget.

---

## Uncertain / Owner-Side Unknowns

- **U1. Actual monthly weighting** of owner's time across dev / K8s / networking /
  cloud / virtualization / vendor work. The research cannot resolve this; it must
  be revealed by the owner before final prioritization.
- **U2. Multi-tenant vs. homelab context**. Hooks designed for production blast-
  radius awareness behave differently in a homelab/lab network. Which is the
  primary use case matters for default settings.
- **U3. Whether `ycc` has an MCP client layer** or expects users to wire MCP
  servers per session. Affects whether safety hooks can inspect tool calls.

---

## Verification Log Summary

- High-confidence findings: 5
- Medium-confidence findings: 3
- Open contradictions: 3 (all classified as productive / addressable)
- Owner-side unknowns: 3 (require direct input)
- Primary sources cited across personas: ~40+ (vendor docs, Anthropic blog,
  CNCF/NANOG/KubeCon programs, Itential catalog, Nautobot release notes)
- Secondary sources: practitioner writing (Pepelnjak, Hightower, Majors, Packet
  Pushers, NetworkToCode)
- Speculation flagged: all futurist timeline predictions marked as such
