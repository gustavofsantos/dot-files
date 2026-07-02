---
name: lgpd-audit
description: Audit a system, repo, or scoped change for violations of the 10 LGPD (Lei 13.709/2018, Art. 6) data-processing principles. Use when the user asks to "check LGPD", "audit privacy", "review for data-protection violations", "LGPD review", or before shipping anything that collects, stores, transmits, logs, or shares personal data of Brazilian residents. Produces a findings report keyed to specific principles, files, and lines. Trigger on PRs/diffs touching user data, new fields/tables, logging, analytics, third-party integrations, exports, or data-retention code.
---

# LGPD Audit

Find where code violates an LGPD Art. 6 principle. The deliverable is a findings list, each item bound to `principle → file:line → why it violates → fix`. Do not lecture on what LGPD is; locate concrete violations.

## Scope first

Establish what you are auditing before grepping. Ask only if unclear:
- Whole repo, a service, or a single diff/PR?
- Is there a documented **purpose** for the data processing (privacy policy, RoPA, ticket)? Without it, principles I/II/III are unauditable except by inference — flag the absence itself as a finding (Art. 6 X).

## What counts as personal data (PII)

Anything identifying a natural person, directly or combined. Sensitive data (Art. 5 II) carries stricter rules: race/ethnicity, health, sex life, biometrics, genetics, religious/political/union affiliation. Children/adolescents data (Art. 14) requires specific consent.

Run `scripts/find_pii.sh <path>` to seed the inventory, then read context — regex finds candidates, not verdicts.

## The 10 principles → code signals

For each, the left is the legal duty; the right is what to look for in source. A signal is a *lead*, not a violation — confirm by reading.

**I. Purpose (finalidade)** — data used only for the stated, specific purpose.
- Signal: a field collected in one flow read by an unrelated module; analytics/ML consuming raw user records; "we might need it later" columns with no consumer.
- Check: trace each PII field from write → all reads. A read outside the declared purpose is a finding.

**II. Adequacy (adequação)** — processing compatible with the informed purpose & context.
- Signal: marketing logic reading data collected for service delivery; repurposing support tickets for training.

**III. Necessity / minimization (necessidade)** — collect only the minimum.
- Signal: `SELECT *` on PII tables; full-object serialization to logs/events/responses; collecting CPF/RG/birthdate when not used; over-broad API responses returning more fields than the caller needs.
- Check: for each collected field, find at least one legitimate consumer. No consumer → minimization finding.

**IV. Free access (livre acesso)** — subject can consult their data & how it's processed.
- Signal: no read/export endpoint for a user's own data; account data only reachable by admins.

**V. Data quality (qualidade)** — accurate, current, correctable.
- Signal: no update path for stored PII; cached/denormalized copies never invalidated; no correction endpoint.

**VI. Transparency (transparência)** — clear info on processing & agents.
- Signal: third-party SDK/data sharing with no corresponding disclosure; trackers/pixels not surfaced in policy; undocumented data flows to processors.

**VII. Security (segurança)** — technical/admin measures against unauthorized access, loss, leak.
- Signal (high-priority, most code-detectable): PII in plaintext logs; secrets/PII in config or fixtures; missing encryption at rest/in transit; no access control on PII endpoints; PII in URLs/query strings; broad DB grants; PII in error messages/stack traces sent to clients or Sentry.
- Run `scripts/scan_security.sh <path>`.

**VIII. Prevention (prevenção)** — measures to prevent harm proactively.
- Signal: no rate limiting / enumeration protection on endpoints exposing PII; no audit log on sensitive reads; no anonymization before analytics.

**IX. Non-discrimination (não discriminação)** — no illicit/abusive discriminatory processing.
- Signal: automated decisions (credit, pricing, eligibility) keyed on sensitive attributes (race, health, gender, neighborhood as proxy); ML features derived from Art. 5 II data. Flag Art. 20 (right to review automated decisions) when found.

**X. Accountability (responsabilização e prestação de contas)** — demonstrable compliance.
- Signal: no retention/deletion logic (data kept forever → also Art. 15/16); no consent record; no audit trail; no RoPA; no DPO reference. Absence of evidence is itself the finding.

## Procedure

1. `scripts/find_pii.sh <path>` → build the PII inventory (field, file, line).
2. `scripts/scan_security.sh <path>` → security/principle-VII leads (logs, plaintext, secrets, PII-in-URL).
3. For each PII field/flow, walk write → reads; test against principles I–III, IX.
4. Check lifecycle for retention/deletion/consent/access/correction (IV, V, X, Art. 15/16).
5. Read every hit in context. Discard false positives. Keep only confirmed or genuinely-suspect items.

## Output format

Group by severity (High = security/sensitive/automated-decision; Medium; Low). One block per finding:

```
[HIGH] VII Security — CPF written to application log
  file: src/payments/charge.clj:142
  evidence: (log/info "charging" {:cpf cpf :amount amt})
  why: plaintext PII in logs = unauthorized-access exposure (Art. 6 VII, Art. 46)
  fix: redact/hash CPF before logging; never log full sensitive identifiers
```

End with: count by principle, and any principles **unauditable from code alone** (needs policy/RoPA/legal) stated explicitly — do not silently pass them.

## Boundaries

You flag technical signals of legal risk; you are not legal counsel. A clean code audit is not legal compliance. State this once in the report. Confirm every finding against the actual code — a false "violation" wastes engineer trust more than a missed lead.
