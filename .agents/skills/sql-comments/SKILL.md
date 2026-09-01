---
name: sql-comments
description: Add useful table and column comments to SQL DDL using the target database's established comment syntax.
---

# SQL Comments

When the repository or user requires schema comments, identify the target SQL dialect from
the existing DDL, migration tool, or database configuration. Match its syntax.

- MySQL and MariaDB can use inline `COMMENT` clauses.
- PostgreSQL uses separate `COMMENT ON TABLE` and `COMMENT ON COLUMN` statements.
- SQL Server commonly uses extended properties.
- If the dialect has no established comment form, ask before adding non-portable syntax.

Comment each table and column covered by the local policy. Explain why it exists or name a
non-obvious unit, lifecycle, privacy boundary, or constraint. Do not restate the identifier.
Keep comments short and preserve the repository's migration style.
