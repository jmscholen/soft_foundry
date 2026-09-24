# Verification Results

Commit SHA: a7e9fd26063487f120cca2d762fa8eeb261f81b0

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| Unit/integration suite, every provider key unset (as on CI) | `ruby -Ilib -Itest -e 'Dir["test/*_test.rb"].each { \|f\| require "./#{f}" }'` with `SOFT_FOUNDRY_GUARD` also unset | 330 runs, 2060 assertions, 0 failures, 0 errors, 0 skips (was 323 / 2002 after control-plane-scan; the 7 new runs are `test/cross_cli_hooks_test.rb`) |
| RED: the new test file run with the worktree at `2357158`, before the implementation existed | `git checkout 2357158 && ruby -Ilib -Itest test/cross_cli_hooks_test.rb` | 7 runs, 13 assertions, 6 failures, 1 errors, 0 skips; `evidence/red-at-2357158.log` |
| Control-plane lint and content scan | `soft-foundry check` | `✓ pass control plane: 16 phases, 17 skills, no errors` |
| Syntax/warnings | `ruby -wc` on every `lib/soft_foundry/*.rb`, `lib/soft_foundry/installer/*.rb`, `lib/soft_foundry.rb`, `exe/soft-foundry`, and the three changed test files | 35 files: Syntax OK, zero warnings |
| End-to-end: `ci` against this repository's own real history, on this stacked branch | `soft-foundry ci` | passes (exit 0) |
| The scan over this whole repository | `soft-foundry scan` | ! warn scan: 0 errors, 5 warnings in 1922 files; the warnings are quoted attacks in earlier records' threat model, attack log, and evaluation transcripts |

## Failures
None at this commit. The RED run is the intended failure, retained as evidence.

## Evidence
`evidence/tests.log`, `evidence/red-at-2357158.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/ci-against-self.log`, `evidence/scan-against-self.log`.

## Scope note
Performed directly by the interactive session, not a fresh-context agent, per `00-intake/assumptions.md`.

Evidence generated for a different implementation commit is stale.
