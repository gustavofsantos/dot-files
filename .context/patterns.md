# Patterns

## Lua

### Find all module requirements
Use this pattern to find where modules are required in Lua files.
```yaml
id: lua-require
language: lua
rule:
  pattern: require($MOD)
```

## Bash

### Find function definitions
(Drafting - needs verification of exact syntax for sg)
```bash
# sg --pattern '$NAME() { $$$ }' --lang bash
```
