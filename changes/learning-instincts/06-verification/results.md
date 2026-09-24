# Verification Results

Commit SHA: a5648d0b5b6933a361a34d30daf9fb77cb740014

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| Unit/integration suite, every provider key unset (as on CI) | `ruby -Ilib -Itest -e 'Dir["test/*_test.rb"].each { \|f\| require "./#{f}" }'` with `SOFT_FOUNDRY_GUARD` also unset | 312 runs, 1923 assertions, 0 failures, 0 errors (was 303 / 1845 after red-green-evidence; the 9 new runs are `test/learning_instincts_test.rb`) |
| RED: the new test file run with the worktree at `a5c0d59`, before the implementation existed | `git checkout a5c0d59 && ruby -Ilib -Itest test/learning_instincts_test.rb` | 9 runs, 4 failures, 5 errors; `evidence/red-at-a5c0d59.log` |
| Control-plane lint | `soft-foundry check` | `✓ pass control plane: 16 phases, 17 skills, no errors` |
| Syntax/warnings | `ruby -wc` on every `lib/soft_foundry/*.rb`, `lib/soft_foundry/installer/*.rb`, `lib/soft_foundry.rb`, `exe/soft-foundry`, and the new test file | 32 files: Syntax OK, zero warnings |
| End-to-end: `ci` against this repository's own real history, on this stacked branch | `soft-foundry ci` | passes (exit 0); the open records on the stack read `on branch ...`; this record's learning gate prints `✓ pass instincts valid: 6 instincts` once the phase is complete |

## Failures
None at this commit. The RED run is the intended failure, retained as evidence.

## Evidence
`evidence/tests.log`, `evidence/red-at-a5c0d59.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/ci-against-self.log`.

## Scope note
Performed directly by the interactive session, not a fresh-context agent, per `00-intake/assumptions.md`.

Evidence generated for a different implementation commit is stale.
