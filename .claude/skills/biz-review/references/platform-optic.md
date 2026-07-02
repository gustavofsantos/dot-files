# Platform Business Optic — Five Dimensions

---

## Dimension 1 — Leverage Multiplier

**The question:** Does this finding enable the platform to create value across multiple teams, or only locally?

Platform value = (per-team benefit × number of adopting teams) − build cost − run cost − per-team migration cost

**Interrogate:**
- Which teams are the consumers? How many?
- What toil or friction does each consumer team bear today that this resolves?
- Is the benefit per team large enough to justify the build cost when multiplied?
- Does benefit scale with team count, or saturate early?

**Signal for "worth acting":** Benefit per team is non-trivial, adopting teams number ≥ 2, and build + run cost is recoverable within a realistic horizon.

---

## Dimension 2 — Adoption Risk

**The question:** Will the teams this is built for actually use it?

A technically perfect platform nobody adopts is 100% cost.

**Interrogate:**
- Is there a paved road / golden path, or do consumers face friction to adopt?
- Opt-in or mandated? (Opt-in has lower forcing function; mandated has higher political cost.)
- What is the per-team migration cost to adopt vs. continuing current behavior?
- Is there an existing tool (internal or OSS) that teams already use for this? Why would they switch?
- Who has the authority to drive adoption? Is that person/team aligned?

**Signal for concern:** High migration cost + opt-in model + no forcing function = probable shelfware.

---

## Dimension 3 — Cognitive Load Delta

**The question:** Does this reduce the cognitive burden on stream-aligned teams, or add a new thing they must learn?

From Team Topologies: platforms justify themselves by reducing cognitive load on the teams doing product delivery. If a platform capability requires consumers to understand its internals, manage its failures, or reason about its edge cases, it has failed its mandate even if technically sound.

**Interrogate:**
- What does a stream-aligned team have to learn to use this?
- What happens when it breaks — does the consumer debug it, or is that fully abstracted?
- Does using this replace a more complex thing the team was doing before, or stack on top?
- Is the interface stable enough that teams won't need to re-learn it across versions?

**Signal for "worth acting":** Net cognitive load on consumers goes down. They interact through a simple, stable interface and don't own the failure surface.

---

## Dimension 4 — Total Cost of Ownership (TCO)

**The question:** What does the full lifespan of this finding, if acted on, cost?

Build cost is the tip of the iceberg for a long-lived platform.

**Interrogate:**
- Build cost: engineering time to implement the finding's implied recommendation
- Run cost: ongoing infrastructure, compute, storage
- Maintenance cost: bug fixes, dependency upgrades, compatibility work over time
- Support cost: answering consumer questions, debugging on-call, writing docs
- Versioning cost: how many consumers break on each interface change?
- Deprecation cost: eventual retirement path — is there one?

**Flag:** If the spike implies a long-lived shared service, probe run + maintenance + deprecation especially. If it implies a one-time script or migration, TCO is mostly build cost.

---

## Dimension 5 — Build / Buy / Adopt-OSS / Do-Nothing

**The question:** Is acting on this spike's finding the right move, compared to all other options?

Platform teams face "why not just use the vendor or the OSS?" constantly. The review must position the spike's implied recommendation honestly.

**Interrogate:**
- **Do-nothing:** What is the concrete cost of staying with the status quo? By when does inaction become untenable?
- **Adopt-OSS:** Is there an open-source project that already answers the question? What's the adoption + integration cost vs. build cost?
- **Buy (vendor):** Is there a vendor solution? What's the license cost vs. build cost + TCO? What's the lock-in risk?
- **Build:** What unique capability does building provide that the alternatives don't? Is that uniqueness worth the TCO?

**Signal:** Prefer buy/adopt-OSS when the problem is commodity and the uniqueness argument is weak. Prefer build when the platform's unique context (team structure, existing infra, data model) makes commodity solutions a poor fit.

---

## Proxy metrics

A platform business review should always propose how success would be measured.

Prefer:
- **DORA metrics** (lead time to change, deployment frequency, change failure rate, MTTR) — if the platform affects delivery pipeline
- **DevEx / SPACE** — developer satisfaction, perceived ease of use, focus time unblocked
- **Adoption rate** — % of eligible teams using the platform capability
- **Support ticket volume** — tracks cognitive load spillover
- **Toil hours reclaimed** — estimated engineering time saved per team per quarter

State which metric fits the spike's finding. If none of these apply, name a proxy that would falsify the benefit claim.
