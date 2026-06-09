# Test Philosophy

Tests are executable documentation. A test should read like a specification of behavior, not an audit of implementation.

## Ordering

Start from the outermost integration or acceptance test that exercises a real end-to-end path. Add unit tests only when a component is complex enough to warrant isolated verification. Never start from the unit level and build inward — that strategy catches bugs late, after coupling has already been designed in.

## Style

Structure tests as BDD scenarios: Given (context) → When (action) → Then (assertion). The test name alone should tell a reader exactly what behavior broke when it fails.

## Discipline

- No conditionals, loops, or shared helpers that hide what is being verified
- Never test private methods — they surface through public interface failures
- Each test should assert one behavior; setup heavier than the assertion signals wrong granularity

## Test friction is a redesign signal

| Friction | Smell |
|---|---|
| Hard to instantiate the subject | Too many dependencies |
| Many mocks required | High coupling |
| Setup longer than assertion | Wrong responsibility boundary |
| Can't assert without side effects | Logic mixed with I/O |

When friction appears, stop and redesign before writing more tests.
