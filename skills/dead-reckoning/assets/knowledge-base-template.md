# Knowledge Base — {System Name}

**Last updated:** {date}

---

## Axioms

External truths asserted by the human. Confirm at every use.

### AX-{id} — {Short label}
{Statement}
**Asserted by:** {name}
**Last confirmed:** {date}

---

## Theorems

Truths confirmed during analysis. Anchored to a commit hash.
If the repo has moved past that hash, revalidate before relying on this theorem.

### TH-{id} — {Short label}
{Statement}
**Anchored at:** {commit hash} ({file:line})
**Depends on axioms:** {AX-id list, or "none"}
**Confirmed:** {date}
**Status:** valid | stale | invalidated

---

## Invalidated

Axioms and theorems that no longer hold. Preserved for history.

### {id} — {label} [INVALIDATED {date}]
{Original statement}
**Reason:** {what changed}
**Cascade:** {theorems that fell with it}
