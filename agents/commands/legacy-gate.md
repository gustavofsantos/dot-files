---
description: Derive and verify .claude/legacy.json so the change-point gate works in this repo
claude:
  argument-hint: "[optional: path hint, e.g. modules/billing]"
  allowed-tools: Bash, Read, Write, Glob, Grep
---

# Context

- Repo root: !`git rev-parse --show-toplevel`
- Tracked files: !`git ls-files | wc -l`
- Test-looking paths: !`git ls-files | grep -iE '(^|/)(tests?|specs?|__tests__)/|[._-](test|spec)s?\.' | head -40`
- Build manifests: !`ls | grep -iE 'deps.edn|project.clj|pom.xml|build.gradle|Gemfile|package.json|Cargo.toml|go.mod|Makefile'`
- Scope hint: $ARGUMENTS

# Task

Write `.claude/legacy.json` with exactly three fields, then prove it works.

```json
{ "gate": "on", "testPathPattern": "<ERE>", "runTests": "<command prefix>" }
```

`testPathPattern` is an ERE matched against repo-relative paths by `grep -E`. It must
partition every tracked file into test or production. Derive it from THIS repo's actual
layout — never from remembered conventions for the stack. Anchor with `(^|/)` for
directory segments and `$` for suffixes.

`runTests` is a command prefix a human appends a target to. It is advisory text the gate
shows the agent. The gate never executes it.

# Acceptance

Do not write the file until all three checks pass. Report each check's output.

**1. Partition is exact.** No production file matches, no test file escapes.

```bash
git ls-files | grep -E "$PAT" | wc -l          # must equal your true test count
git ls-files | grep -E "$PAT" | grep -vE 'test|spec' | head   # must be empty
git ls-files | grep -vE "$PAT" | xargs grep -lE 'deftest|@Test|describe\(|def test_|it\(' 2>/dev/null | head
```

The third command is the important one: any file it prints is a test your pattern
missed. Fix the pattern. Never widen it to a bare substring — verify why it escaped.

**2. runTests actually runs.** Execute it once against a single real test target. If it
errors, the prefix is wrong. Find the correct single-target invocation and re-run.

**3. The gate answers correctly.** Pick two files by hand: one you can see is pinned by a
test, one you can see is not. Drive the hook directly and assert the decisions.

```bash
for f in <COVERED_FILE> <UNCOVERED_FILE>; do
  printf '{"session_id":"probe","tool_input":{"file_path":"%s"}}' "$PWD/$f" \
    | change-point-gate --harness claude | jq -r '.hookSpecificOutput.permissionDecision // "allow(silent)"'
done
```

Expect `allow` then `deny`. Any other pair means the config is wrong, not the gate —
`allow allow` usually means the uncovered file's stem collides with an unrelated test.
`deny deny` usually means `testPathPattern` failed to see the covering test at all.
Diagnose before adjusting. Use `session_id` values other than `probe` when re-running,
since the gate caches its verdict per session.

# Report

State the pattern, the two probe files, the three check outputs, and any file whose
classification you were unsure about. If a repo has no tests at all, say so. Write
`"gate": "off"` with a one-line reason. A gate that cannot observe anything is worse
than no gate.
