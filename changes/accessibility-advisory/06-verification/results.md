# Verification Results

Commit SHA: 2c74a369fe3ab24c4da40242dff5e6624f7fd8ef

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| Unit/integration suite, every provider key unset (as on CI) | `ruby -Ilib -Itest -e 'Dir["test/*_test.rb"].each { \|f\| require "./#{f}" }'` | 223 runs, 1346 assertions, 0 failures, 0 errors (was 199 runs / 1254 assertions before this change) |
| Control-plane lint | `soft-foundry check` | `✓ pass control plane: 16 phases, 16 skills, no errors` |
| Syntax/warnings | `ruby -wc` on every `lib/soft_foundry/*.rb`, `lib/soft_foundry/installer/*.rb`, `exe/soft-foundry`, and the new/changed test files | 30 files: Syntax OK, zero warnings |
| End-to-end: `ci` against this repository's own real history | `soft-foundry ci` | passes (exit 0); prints the new `advisory:` block for this change record (specification skipped, judgment skipped, review not yet run at that commit) and nothing for the eight closed records |

## Failures
None. One test failure occurred during development and was fixed before this commit: the framework list in `.ai/repository.yml` is kept in profile order, so `change new`'s comment printed `(react, express)` where the test expected sorted output; both `ChangeRecord#declare_accessibility_surface!` and `Advisory#repository_ui_frameworks` now sort.

## Evidence
`evidence/tests.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/ci-against-self.log`.

## Scope note
Performed directly by the interactive session, not a fresh-context agent, per `00-intake/assumptions.md`.

Evidence generated for a different implementation commit is stale.
