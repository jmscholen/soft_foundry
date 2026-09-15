# Verification Results

Commit SHA: 05f44e9a6dd62a01ffc926e903aa8c6898f36ec2

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| Unit/integration suite, every provider key unset (as on CI) | `ruby -Ilib -Itest -e 'Dir["test/*_test.rb"].each { \|f\| require "./#{f}" }'` | 240 runs, 1421 assertions, 0 failures, 0 errors (was 223 runs / 1346 assertions before this change) |
| Control-plane lint | `soft-foundry check` | `✓ pass control plane: 16 phases, 16 skills, no errors` |
| Syntax/warnings | `ruby -wc` on every `lib/soft_foundry/*.rb`, `lib/soft_foundry/installer/*.rb`, `exe/soft-foundry`, and the changed test files | 32 files: Syntax OK, zero warnings |
| End-to-end: `ci` against this repository's own real history | `soft-foundry ci` | passes (exit 0); the ten closed records are skipped, `upstream-failure-reporting` still passes, and this record prints the expected `advisory:` block (judgment skipped; accessibility requirements not recorded because specification is skipped; accessibility review not yet run at that commit) |

## Failures
None at this commit. During development the evaluation script first ran under Ruby 2.7.8 because the scratch directory sits outside the repository's version-manager configuration; the CLI refused with its own version message and the script was pointed at the Ruby 3.3.1 binary. Not a defect in the change.

## Evidence
`evidence/tests.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/ci-against-self.log`.

## Scope note
Performed directly by the interactive session, not a fresh-context agent, per `00-intake/assumptions.md`.

Evidence generated for a different implementation commit is stale.
