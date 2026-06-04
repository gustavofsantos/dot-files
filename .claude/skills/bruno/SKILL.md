---
name: bruno
description: >
  Bruno API client using the YAML/OpenCollection format. Use when the repo
  contains opencollection.yml and .yml request files. For bruno.json + .bru
  files, use the brulang skill instead.
---

# Bruno API Client — YAML / OpenCollection Format

> **Format detection**: `opencollection.yml` + `.yml` request files → this skill.
> `bruno.json` + `.bru` request files → use **`brulang`** skill instead.

Spec: [OpenCollection](https://spec.opencollection.com/)

## File Structure
```
My Collection/
├── opencollection.yml        # REQUIRED — must have opencollection version header
├── collection.yml            # collection-level settings (optional)
├── environments/
│   └── Local.yml
├── Get User.yml              # request files
└── Users/
    ├── folder.yml
    └── Get User by ID.yml
```

## opencollection.yml
```yaml
opencollection: 1.0.0

info:
  name: Your Collection Name
```
Only `info:`, `config:`, `request:` (variables/scripts), and `docs:` belong here.
**Do not** add `http:` — that belongs in individual request files.

## Request file (.yml)
```yaml
info:
  name: API Request Name
  type: http
  seq: 1

http:
  method: GET
  url: "{{baseUrl}}/api/endpoint"
  auth:
    type: bearer
    token: "{{authToken}}"

runtime:
  scripts:
    - type: before-request
      code: bru.setVar("timestamp", Date.now());
    - type: after-response
      code: bru.setVar("userId", res.body.id);
    - type: tests
      code: |-
        test("Status is 200", function() {
          expect(res.status).to.equal(200);
        });
```

## Environment file
```yaml
variables:
  - name: baseUrl
    value: https://api.example.com
  - name: apiKey
    value: ""
    secret: true
```

## Common Mistakes
- ❌ Missing `opencollection.yml` — every collection MUST have one
- ❌ Using `meta:` instead of `info:` — use `info:` for request metadata
- ❌ Putting `http:` blocks in `opencollection.yml` — request details go in separate `.yml` files
- ❌ Using `test` instead of `tests` for script type
- ❌ Putting tests at root level — they belong under `runtime: scripts:`
- ❌ Using `.yaml` extension — Bruno uses `.yml`
