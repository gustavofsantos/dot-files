---
name: bruno
description: >
  Bruno API client collections — creating or editing request files, environments,
  scripts, or tests. Use when the repo contains a Bruno collection in either format:
  bruno.json with .bru request files (legacy), or opencollection.yml with .yml
  request files (OpenCollection).
---

# Bruno API Client

Two on-disk formats exist. Detect which one the collection uses, then load **only**
that format's reference — the formats are not interchangeable and must not be mixed.

| Marker in repo | Format | Load |
|---|---|---|
| `bruno.json` + `.bru` files | Legacy Bru | [references/bru-format.md](references/bru-format.md) |
| `opencollection.yml` + `.yml` files | OpenCollection | [references/opencollection-format.md](references/opencollection-format.md) |

If both markers exist, the directory containing the file being edited wins. When
creating a brand-new collection and the user hasn't said which format, prefer
OpenCollection (the current format) and say so.

Shared runtime facts (both formats):
- `bru.setVar`/`bru.getVar` bridge values between requests; `{{var}}` interpolates in URLs, headers, bodies.
- Tests use Chai-style `expect` with `res.status`, `res.body`.
- Secret variables never store values in committed files — values come from the selected environment at runtime.
