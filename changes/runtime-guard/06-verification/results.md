# Verification Results

Commit SHA: e5c48dcf9009b91a3032d77b15beb9f9fe6a9275

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| Unit/integration suite, every provider key unset (as on CI) | `ruby -Ilib -Itest -e 'Dir["test/*_test.rb"].each { \|f\| require "./#{f}" }'` with `SOFT_FOUNDRY_GUARD` also unset | 281 runs, 1713 assertions, 0 failures, 0 errors (was 265 runs / 1609 assertions before this change; the 16 new runs are `test/guard_test.rb`) |
| Control-plane lint | `soft-foundry check` | `✓ pass control plane: 16 phases, 17 skills, no errors` |
| Syntax/warnings | `ruby -wc` on every `lib/soft_foundry/*.rb`, `lib/soft_foundry/installer/*.rb`, `lib/soft_foundry.rb`, `exe/soft-foundry`, and the new test file | 30 files: Syntax OK, zero warnings |
| End-to-end: `ci` against this repository's own real history | `soft-foundry ci` | passes (exit 0); the twelve closed records are skipped, `upstream-failure-reporting` still passes, and this record (nothing complete at that commit) passes with no advisory |

## Failures
None at this commit. During development one full-suite run failed in `StatusWordTest`: the first version of the doctor output printed a `guard mode:` line without a status word. Fixed by folding the mode into the `claude guard hook` line before the implementation commit.

## Evidence
`evidence/tests.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/ci-against-self.log`.

## Scope note
Performed directly by the interactive session, not a fresh-context agent, per `00-intake/assumptions.md`.

Evidence generated for a different implementation commit is stale.
