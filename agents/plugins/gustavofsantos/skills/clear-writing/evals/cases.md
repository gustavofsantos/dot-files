# Evaluation Cases

A correct implementation should preserve the protected semantics in each case.

## 1. Correlation is not causation

Input:

> Error rates increased after deployment X.

Forbidden rewrite:

> Deployment X caused the increase in errors.

Expected behavior:

Preserve the temporal relationship unless evidence proves causation.

---

## 2. Uncertainty must remain uncertainty

Input:

> The timeout may be related to connection pool exhaustion.

Forbidden rewrite:

> The timeout is caused by connection pool exhaustion.

Expected behavior:

Preserve `may` or explicitly identify the claim as a hypothesis.

---

## 3. Approximation must remain approximation

Input:

> The service processed approximately 10k events/minute under the tested workload.

Forbidden rewrite:

> The service processes 10k events/minute.

Expected behavior:

Preserve both the approximation and the workload constraint.

---

## 4. Requirement strength

Input:

> The client should retry transient failures.

Forbidden rewrite:

> The client must retry transient failures.

Expected behavior:

Preserve `should`.

---

## 5. Percentage vs percentage points

Input:

> Conversion increased from 10% to 13%, an increase of 3 percentage points.

Forbidden rewrite:

> Conversion increased by 3%.

Expected behavior:

Preserve the difference.

---

## 6. Contradictory evidence

Document:

> The worker retries failed jobs three times.

Source A:

> MAX_RETRIES = 3

Source B:

> Documentation says the worker retries five times.

Expected behavior:

Report the contradiction. Do not silently choose one source.

---

## 7. Portuguese bureaucratic prose

Input:

> Foi realizada a implementação de um mecanismo com o objetivo de efetuar a validação dos eventos.

Acceptable rewrite:

> Implementamos um mecanismo para validar os eventos.

Only use the explicit actor if ownership is known or present in context.

---

## 8. Identifier preservation

Input:

> The `shipment_id` field is required by `create_shipment`.

Forbidden rewrite:

> The `shipmentId` field is required by `createShipment`.

Expected behavior:

Preserve code identifiers exactly.

---

## 9. Recommendation is not a decision

Input:

> We recommend migrating the workload to Kafka.

Forbidden rewrite:

> We will migrate the workload to Kafka.

Expected behavior:

Preserve recommendation status.

---

## 10. False absolute

Input:

> The retry policy reduces the probability of transient failures reaching the user.

Forbidden rewrite:

> The retry policy ensures that transient failures never reach the user.

Expected behavior:

Do not introduce guarantees.
