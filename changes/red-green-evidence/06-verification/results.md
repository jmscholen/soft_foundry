# Verification Results

Commit SHA: 7306119ba99bd292ef70dd509fd68697a651b81c

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| Unit/integration suite, every provider key unset (as on CI) | `ruby -Ilib -Itest -e 'Dir["test/*_test.rb"].each { \|f\| require "./#{f}" }'` with `SOFT_FOUNDRY_GUARD` also unset | 303 runs, 1845 assertions, 0 failures, 0 errors (was 294 runs / 1809 assertions after phase-runner; the 9 new runs are `test/red_green_test.rb`) |
| RED: the new test file run with the worktree at `5d898e0`, before the implementation existed | `git checkout 5d898e0 && ruby -Ilib -Itest test/red_green_test.rb` | 9 runs, 2 assertions, 0 failures, 8 errors (no `red evidence` check, no `verification` advisory area yet); `evidence/red-at-5d898e0.log` |
| Control-plane lint | `soft-foundry check` | `✓ pass control plane: 16 phases, 17 skills, no errors` |
| Syntax/warnings | `ruby -wc` on every `lib/soft_foundry/*.rb`, `lib/soft_foundry/installer/*.rb`, `lib/soft_foundry.rb`, `exe/soft-foundry`, and the new test file | 31 files: Syntax OK, zero warnings |
| End-to-end: `ci` against this repository's own real history, on this stacked branch | `soft-foundry ci` | passes (exit 0); the twelve closed records are skipped; the open `runtime-guard` and `phase-runner` records now each carry the new `! warn verification:` advisory (neither was done test-first), which is this change reporting on its predecessors |

## Failures
None at this commit. The RED run above is the intended failure and is retained as evidence, not a defect.

## Evidence
`evidence/tests.log`, `evidence/red-at-5d898e0.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/ci-against-self.log`.

## Scope note
Performed directly by the interactive session, not a fresh-context agent, per `00-intake/assumptions.md`.

Evidence generated for a different implementation commit is stale.
