---
paths:
  - "**/*.{clj,kt,kts,java,py,ts,js,go,rb}"
---

# Logging

- Log only what is needed to pivot into DB/Sentry: entity IDs, correlation ID. Log the key, never the row/payload (recoverable by query).
- Error → Sentry XOR log, never both (duplication). Sentry: unexpected/actionable, exactly once at the owning boundary. Log (WARN/INFO): expected handled conditions. Never log-and-rethrow.
- Stdout is I/O cost: no per-item logs in loops/batches. One summary line (counts, duration, failures). Guard expensive construction behind level checks. High-frequency → metrics/sampling, not logs.
- Structured key-value fields, not prose. Levels: ERROR is Sentry-only. WARN is degraded but handled. INFO is business state transitions only. DEBUG is off in prod.
- Never log secrets, PII, payloads, or stack traces for expected conditions. When in doubt, omit the log.
