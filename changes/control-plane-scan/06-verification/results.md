# Verification Results

Commit SHA: 54ecc50a2f6410961901537cbcb8b89085085254

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| Unit/integration suite, every provider key unset (as on CI) | `ruby -Ilib -Itest -e 'Dir["test/*_test.rb"].each { \|f\| require "./#{f}" }'` with `SOFT_FOUNDRY_GUARD` also unset | 323 runs, 2002 assertions, 0 failures, 0 errors, 0 skips (was 312 / 1923 after learning-instincts; the 11 new runs are `test/content_scan_test.rb`) |
| RED: the new test file run with the worktree at `71d987f`, before the implementation existed | `git checkout 71d987f && ruby -Ilib -Itest test/content_scan_test.rb` | 9 runs, 4 assertions, 2 failures, 6 errors, 0 skips; `evidence/red-at-71d987f.log` |
| Control-plane lint, now including the content scan of `.ai/`, `AGENTS.md`, `CLAUDE.md` | `soft-foundry check` | `✓ pass control plane: 16 phases, 17 skills, no errors` |
| Syntax/warnings | `ruby -wc` on every `lib/soft_foundry/*.rb`, `lib/soft_foundry/installer/*.rb`, `lib/soft_foundry.rb`, `exe/soft-foundry`, and the two changed test files | 33 files: Syntax OK, zero warnings |
| End-to-end: `ci` against this repository's own real history, on this stacked branch | `soft-foundry ci` | passes (exit 0); every complete phase of every open record now prints `✓ pass content clean` |
| The scan over this whole repository, this record's evidence included | `soft-foundry scan` | ! warn scan: 0 errors, 5 warnings in 1840 files: the warnings are `init-command`'s threat model and attack log quoting an injection, and this record's own transcript quoting the attacks its journeys injected; `evidence/scan-against-self.log` |

## Failures
None at this commit. The RED run is the intended failure, retained as evidence. One full-suite run at the first GREEN commit (`1e2de98`) failed three learning tests because the fixture assumed an empty `learned.md`; the fixture reset is in `54ecc50a2f6410961901537cbcb8b89085085254` and this evidence is generated there.

## Evidence
`evidence/tests.log`, `evidence/red-at-71d987f.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/ci-against-self.log`, `evidence/scan-against-self.log`.

## Scope note
Performed directly by the interactive session, not a fresh-context agent, per `00-intake/assumptions.md`.

Evidence generated for a different implementation commit is stale.
