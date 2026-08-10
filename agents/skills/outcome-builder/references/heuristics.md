# Outcome-Driven Heuristics — Reference

This guide helps distinguish between outputs (features, mechanisms) and outcomes (value, state transitions), and provides rules for constructing strong logical assertions.

---

## 1. Output vs. Outcome Mindset

| Output (What we build) | Outcome (What changes for the user/system) |
| :--- | :--- |
| Add an OAuth login button. | Users can securely authenticate using their company identity. |
| Create a Cron job to clean logs. | Disk space utilization remains below 85% automatically. |
| Build a Postgres database index. | Search response times remain under 200ms at scale. |
| Implement a modal dialog box. | Users are warned about destructive actions before confirmation. |

---

## 2. Drafting Strong `ASSERT` Anchors

A good outcome anchor has three distinct parts:
`ASSERT: The system satisfies [Outcome] (Verification: [Proof]), regardless of whether we use [Mechanism] or a simpler alternative.`

### Weak vs. Strong Examples

❌ **Weak (Doesn't decouple mechanism):**
> `ASSERT: The system satisfies [adding a Redis cache] (Verification: [Redis gets hits on search queries]), regardless of whether we use [Redis] or a simpler alternative.`
* **Why it's weak:** The outcome *is* the mechanism. If Redis is down or too complex, the LLM has no room to pivot.

* **Why it's strong:** The outcome is the target behavior (speed). The verification is measurable. The mechanism (Redis) is explicitly marked as negotiable. If the LLM can achieve <200ms using in-memory local caching or database optimization, it is allowed to do so.

---

## 3. Heuristics for Verification Conditions

* **Observable:** The verification must be checkable via a test script, terminal command, or direct UI inspection (e.g., "command `npm test` passes", "server returns 200 and a JSON payload", "UI displays a banner").
* **Non-Implementation Specific:** Avoid mentioning specific databases, library APIs, or class names in the verification unless they are hard requirements of the system architecture.
* **Minimal:** A single primary verification is usually enough. If you need more than 3 verification steps, the outcome is too broad and should be split.
