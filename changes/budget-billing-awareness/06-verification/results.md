# Verification Results

Commit SHA: f47178af37dc4e7c9542cb4fe10b29c292029e5b

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| Unit/integration suite | `ruby -Ilib -Itest -e 'Dir["test/*_test.rb"].each { \|f\| require "./#{f}" }'` | 199 runs, 1254 assertions, 0 failures, 0 errors (was 175 runs / 1081 assertions before this change) |
| Control-plane lint | `soft-foundry check` | 16 phases, 16 skills, no errors |
| Syntax/warnings | `ruby -wc` on every `lib/soft_foundry/*.rb`, `lib/soft_foundry/installer/*.rb`, `exe/soft-foundry`, and every new/changed test file | 30 files: Syntax OK, zero warnings |
| End-to-end: `ci` against this repository's own real history | `soft-foundry ci` | passes cleanly, including this change record itself |

## Failures
None remaining. Two real defects (IMP-1, IMP-2 in 05-implementation/log.md) were found and fixed before this verification pass, each with a dedicated regression test.

## Evidence
`evidence/tests.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/ci-against-self.log`.

## Scope note
Performed directly by the interactive session, not a fresh-context agent, per the lighter-weight process recorded in `00-intake/assumptions.md`.

Evidence generated for a different implementation commit is stale.
