---
paths:
  - "**/*.{clj,kt,kts,java,py,ts,js,go,rb}"
---

# Logging

- Log only what's needed to pivot into DB/Sentry: entity IDs, correlation ID. Log the key, never the row/payload (recoverable by query).
- Error → Sentry XOR log, never both (duplication). Sentry: unexpected/actionable, exactly once at the owning boundary. Log (WARN/INFO): expected handled conditions. Never log-and-rethrow.
- Stdout is I/O cost: no per-item logs in loops/batches — one summary line (counts, duration, failures). Guard expensive construction behind level checks. High-frequency → metrics/sampling, not logs.
- Structured key-value fields, not prose. ERROR=Sentry-only; WARN=degraded but handled; INFO=business state transitions only; DEBUG=off in prod.
- Never log secrets, PII, payloads, or stack traces for expected conditions. When in doubt, omit the log.
