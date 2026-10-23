# Assumptions

## Explicit assumptions
- `phase reopen` is a CLI command acting on the change record on disk; it edits only handoff status and history, never evidence files or code, and the history lives in `metadata.yml` next to the existing `reopenings` list or a new key.
- "Downstream" means the phases after the reopened one in lifecycle order, plus the loop transitions already in `workflow.yml`.
- `phase run --parallel` runs only the phases the workflow declares isolated; which phases are isolated is declared in `workflow.yml`, not guessed in Ruby. Isolation depends on the adopter giving each run its own state (for example `DATABASE_URL`); Soft Foundry passes a per-run value through, it does not provision resources.
- `released` is a status value in `metadata.yml` with a list of named open items, each with an id and a description; `ci` accepts it where it now requires `closed` for a merged change.

## Ambiguities resolved
- Scope is items 4, 5, 6 only; item 7 is change C. The maintainer chose this split.
- Nothing here is `my_ai`-specific; the report's examples (ENG-GOLIVE-001, `DATABASE_URL`) are illustrations of the adopter case.

## Ambiguities that block safe progress
None. Open design questions (the history key name, how a runner detects stale evidence safely, how parallel results are committed without racing, what discharges a released item) belong to specification and are not blocking.
