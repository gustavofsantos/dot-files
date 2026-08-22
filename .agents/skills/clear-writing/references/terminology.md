# Terminology

Terminology consistency is part of correctness.

## Priority

Prefer:

1. project terminology
2. company terminology
3. industry terminology
4. generic language preferences

## One concept, one term

Avoid accidental synonym rotation.

If a document uses `shipment`, do not alternate among:

- shipment
- package
- parcel
- delivery

unless those terms represent different concepts.

## One term, one concept

Flag overloaded words when the same term refers to different things.

## Acronyms

For unfamiliar acronyms:

1. write the full name on first use
2. add the acronym in parentheses
3. use the acronym consistently afterward

Do not expand an acronym unless the expansion is known.

## Code and identifiers

Preserve exactly:

- function names
- class names
- event names
- table names
- configuration keys
- API fields
- metric names
- service names

Use code formatting when appropriate.

## Project configuration

If `.clear-writing.yml` exists, read it before editing.

Suggested fields:

```yaml
language: en

preferred_terms:
  customer: shipper

protected_terms:
  - Beyond
  - timeslot-service
  - shipment_id

acronyms:
  SLA: Service Level Agreement

discouraged_terms:
  - obviously
  - simply
  - clearly

sources:
  - docs/architecture/
  - docs/glossary.md
```

Treat project configuration as policy, not as factual evidence by itself.
