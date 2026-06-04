---
name: brulang
description: >
  Bruno API client using the legacy .bru format. Use when the repo contains
  bruno.json and .bru request files. For opencollection.yml + .yml files, use
  the bruno skill instead.
---

# Bruno API Client — Legacy `.bru` Format

> **Format detection**: `bruno.json` + `.bru` request files → this skill.
> `opencollection.yml` + `.yml` request files → use **`bruno`** skill instead.

Spec: [Bruno docs](https://docs.usebruno.com/)

## File Structure
- `bruno.json` — collection metadata/settings (REQUIRED)
- `collection.bru` — collection-level configuration
- `environments/*.bru` — environment files
- `*.bru` — individual request files
- `folder.bru` — folder-level settings

## Request file (.bru)
```bru
meta {
  name: API Request Name
  type: http
  seq: 1
}

get {
  url: {{baseUrl}}/api/endpoint
  body: none
  auth: none
}

headers {
  content-type: application/json
  authorization: Bearer {{token}}
}

body:json {
  {
    "key": "value"
  }
}

script:pre-request {
  bru.setVar("timestamp", Date.now());
}

script:post-response {
  bru.setVar("userId", res.body.id);
}

tests {
  test("Status is 200", function() {
    expect(res.status).to.equal(200);
  });
}
```

## Environment file
```bru
vars {
  baseUrl: https://api.example.com
  timeout: 5000
}

vars:secret [
  apiKey,
  authToken
]
```

## Quirks
- **Method is the block name**: use `get { ... }`, `post { ... }` — there is no `method:` key.
- **Script namespacing**: `script:pre-request` and `script:post-response` (colon-separated), not `script { type: pre-request }`.
- **Tests block**: bare `tests { ... }`, NOT `script:tests`.
- **Secrets in env files**: `vars:secret` is an array of *names*, not key-value pairs — values come from the environment, not the file.
- **GraphQL variables**: go in a separate `body:graphql:vars` block, not nested inside `body:graphql`.
- **`vars:pre-request` / `vars:post-response`**: inline variable extraction blocks distinct from scripts.
