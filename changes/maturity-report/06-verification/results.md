# Verification Results

Commit SHA: 9f994c0170ab66e81b2957d5d16b79f487a4f4d5 (bound after commit; see handoff.yml)

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| Unit/integration suite | `ruby -Ilib -Itest -e '...'` | 146 runs, 999 assertions, 0 failures, 0 errors |
| Control-plane lint | `soft-foundry check` | 16 phases, 16 skills, no errors |
| Syntax/warnings | `ruby -wc` on every `lib/soft_foundry/**/*.rb` and `exe/soft-foundry` | 24 files, Syntax OK, zero warnings |
| End-to-end scan + already-assessed skip path, real mtime check | fresh scratch git repo, Ruby 3.3.1 | see `evidence/e2e-smoke.log` |

## Failures
None. One real bug (ASCII-8BIT vs UTF-8 `String#==` defeating the idempotency check) was found by direct in-process repro, fixed, and covered by a regression test before this verification pass; see `05-implementation/log.md`.

## Evidence
`evidence/tests.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/e2e-smoke.log`.

## Scope note
Performed directly by the interactive session, not a fresh-context agent, per the lighter-weight process recorded in `00-intake/assumptions.md`.

Evidence generated for a different implementation commit is stale.
