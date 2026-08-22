---
name: sql-comments
description: Add COMMENT clauses to every table and column in SQL DDL, explaining why the field exists or any non-obvious constraint rather than restating the column name. Use whenever writing or modifying a CREATE TABLE, ALTER TABLE, or other DDL statement.
---

When writing or modifying SQL DDL, always add `COMMENT` clauses to tables and columns.

```sql
-- Good
CREATE TABLE contract (
  id          BIGINT      NOT NULL COMMENT 'Internal surrogate key',
  external_id VARCHAR(36) NOT NULL COMMENT 'UUID exposed to external systems',
  status      VARCHAR(20) NOT NULL COMMENT 'lifecycle state: active | terminated | suspended'
) COMMENT = 'Lease agreements between landlord and tenant';

-- Also valid (ALTER)
ALTER TABLE invoice
  MODIFY COLUMN due_amount DECIMAL(15,2) NOT NULL COMMENT 'Amount owed in BRL cents';
```

Keep comments short (one line) and focus on *why the field exists* or any non-obvious constraints — not just a restatement of the column name.
