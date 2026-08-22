---
name: rules-of-logging
description: Enforce logging discipline — Sentry XOR log (never both), no per-item logs in loops, structured key-value fields, correct log levels, never log secrets/PII/payloads. Use whenever writing or reviewing a log statement, error handler, or Sentry capture in application code (Clojure, Kotlin, Java, Python, TypeScript, JavaScript, Go, Ruby). Trigger even on a bare "add logging" or "catch and log this error".
---

# Logging

1. Log only what is needed to pivot into DB/Sentry: entity IDs, correlation ID. Log the key, never the row/payload (recoverable by query).
2. Error → Sentry XOR log, never both (duplication). Sentry: unexpected/actionable, exactly once at the owning boundary. Log (WARN/INFO): expected handled conditions. Never log-and-rethrow.
3. Stdout is I/O cost: no per-item logs in loops/batches. One summary line (counts, duration, failures). Guard expensive construction behind level checks. High-frequency → metrics/sampling, not logs.
4. Structured key-value fields, not prose. Levels: ERROR is Sentry-only. WARN is degraded but handled. INFO is business state transitions only. DEBUG is off in prod.
5. Never log secrets, PII, payloads, or stack traces for expected conditions. When in doubt, omit the log.
