-- trace: full life of one contract across every context
-- usage: replace :key with the contract id
-- add a UNION ALL block each time a new system proves relevant

WITH ev AS (
  SELECT c.contract_id                      AS k,
         c.created_at                       AS t,
         c.ts_cdc_transaction               AS seen,
         'cart'                             AS src,
         'contract ' || c.status            AS event,
         cast(c.id AS varchar)              AS ref
  FROM delta.datalake_cart_clean.contract c
  WHERE c.contract_id = :key

  UNION ALL
  SELECT i.contract_id,
         i.issued_at,
         i.ts_cdc_transaction,
         'billing',
         'invoice ' || i.status,
         cast(i.id AS varchar)
  FROM delta.datalake_billing_clean.invoice i
  WHERE i.contract_id = :key

  UNION ALL
  SELECT o.contract_ref,
         o.created_at,
         o.ts_cdc_transaction,
         'fintech',
         'order ' || o.status,
         cast(o.id AS varchar)
  FROM delta.datalake_fintech_clean.order o
  WHERE o.contract_ref = :key
)
SELECT t,
       seen,
       date_diff('minute', t, seen) AS lag_min,
       src,
       event,
       ref
FROM ev
ORDER BY t
