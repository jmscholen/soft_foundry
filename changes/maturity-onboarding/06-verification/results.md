# Verification Results

Commit SHA: 142baec75fd21d3f0e1bed73d50bf18fddafe719 (bound after commit; see handoff.yml)

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| Unit/integration suite | `ruby -Ilib -Itest -e '...'` | 117 runs, 889 assertions, 0 failures, 0 errors |
| Control-plane lint | `soft-foundry check` | 16 phases, 16 skills, no errors |
| Syntax/warnings | `ruby -wc` on every `lib/soft_foundry/**/*.rb` and `exe/soft-foundry` | 21 files, Syntax OK, zero warnings |
| End-to-end scan, skip, reassess | fresh scratch git repo, Ruby 3.3.1, real Gemfile/spec | see `evidence/e2e-smoke.log` |

## Failures
None.

## Evidence
`evidence/tests.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/e2e-smoke.log`.

## Scope note
Performed directly by the interactive session, not a fresh-context agent, per the lighter-weight process recorded in `00-intake/assumptions.md`. `deep` mode's subprocess behavior is covered by unit tests using an injectable runner (`test/maturity_deep_assess_test.rb`), not a real `claude` invocation; a genuine `claude -p` run was not exercised as part of this verification.

Evidence generated for a different implementation commit is stale.
