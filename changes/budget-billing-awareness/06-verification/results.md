# Verification Results

Commit SHA: c48e867d6c4060bcc039341ab1b2c92626268b6e

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| Unit/integration suite, every provider key unset (as on CI) | `ruby -Ilib -Itest -e 'Dir["test/*_test.rb"].each { \|f\| require "./#{f}" }'` | 199 runs, 1254 assertions, 0 failures, 0 errors (was 175 runs / 1081 assertions before this change) |
| Control-plane lint | `soft-foundry check` | 16 phases, 16 skills, no errors |
| Syntax/warnings | `ruby -wc` on every `lib/soft_foundry/*.rb`, `lib/soft_foundry/installer/*.rb`, `exe/soft-foundry`, and every new/changed test file | 31 files: Syntax OK, zero warnings |
| End-to-end: `ci` against this repository's own real history | `soft-foundry ci` | passes cleanly, including this change record itself |

## Failures
None remaining. Three real defects (IMP-1, IMP-2, IMP-3 in 05-implementation/log.md) were found and fixed before this verification pass. IMP-3 surfaced only on the GitHub runner: the suite is now run for this evidence with every provider key unset, matching CI, and was also confirmed passing with keys exported and with SOFT_FOUNDRY_BILLING=subscription forced.

## Evidence
`evidence/tests.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/ci-against-self.log`.

## Scope note
Performed directly by the interactive session, not a fresh-context agent, per the lighter-weight process recorded in `00-intake/assumptions.md`.

Evidence generated for a different implementation commit is stale.
