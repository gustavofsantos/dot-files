---
name: rules-of-logging
description: >
  Apply a focused logging profile with safe fields, bounded volume, structured events, and
  single-owner error reporting.
disable-model-invocation: true
---

# Logging

1. Never log secrets, personal data, credentials, or full payloads. Log only the safe
   identifiers needed to correlate the event with protected data sources.
2. Emit one structured event at the boundary that owns the outcome. Do not log and
   rethrow the same error at successive layers.
3. Do not emit per-item logs in loops or batches. Emit a summary with counts, duration,
   and failures. Use metrics or sampling for high-frequency signals.
4. Follow the repository's established levels and production settings. Guard expensive
   field construction behind enabled-level checks.
5. In environments whose policy routes unexpected actionable errors to Sentry, capture
   once in Sentry or log the error, not both. Treat expected handled conditions according
   to that environment's log-level policy.
