-- INV-014
-- claim:     every issued invoice has a matching fintech order
-- contexts:  billing, fintech-order
-- watermark: 4h  (p99 ingestion lag of fintech-order, measured 2026-08-05)
-- exception: none
-- must return ZERO rows

SELECT i.id            AS invoice_id,
       i.contract_id,
       i.issued_at,
       i.amount
FROM delta.datalake_billing_clean.invoice i
LEFT JOIN delta.datalake_fintech_clean.order o
  ON  o.contract_ref    = i.contract_id
  AND o.reference_month = i.reference_month
WHERE i.status = 'ISSUED'
  AND o.id IS NULL
  AND i.ts_cdc_transaction < current_timestamp - interval '4' hour
ORDER BY i.issued_at DESC
