# Verification Results

Commit SHA: 9f6ecfc5ac2672a976475a56eca0f8a09ff68c19

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| Unit/integration suite | `ruby -Ilib -Itest -e 'Dir["test/*_test.rb"].each { |f| require "./#{f}" }'` | 174 runs, 1077 assertions, 0 failures, 0 errors |
| Control-plane lint | `soft-foundry check` | 16 phases, 16 skills, no errors |
| Syntax/warnings | `ruby -wc` on every `lib/soft_foundry/*.rb`, `exe/soft-foundry`, and every new/changed test file | all files: Syntax OK, zero warnings |
| End-to-end: `ci` against this repository's own real history | `soft-foundry ci` | passes cleanly, including this change record itself and the corrected (non-false-positive) treatment of `changes/upstream-failure-reporting` |

## Failures
None remaining. One real bug (see 05-implementation/log.md, IMP-1) was found by running the new check against this repository's own history, fixed with `commit_sha_at_judgment`, and locked in with a dedicated regression test before this verification pass.

## Evidence
`evidence/tests.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/ci-against-self.log`.

## Scope note
Performed directly by the interactive session, not a fresh-context agent, per the lighter-weight process recorded in `00-intake/assumptions.md`.

Evidence generated for a different implementation commit is stale.
