# Verification Results

Commit SHA: 5dfa6b4b4fc79552c0d6c188ab02b98998c01d7e

## Deterministic checks
- CHECK-001 full suite with provider keys, Soft Foundry overrides, and `GITHUB_TOKEN` unset: 437 runs, 2889 assertions, 0 failures, 0 errors, 0 skips.
- CHECK-002 `test/updater_github_test.rb` at the RED commit `1da10bc`: 8 errors. Retained as RED evidence.
- CHECK-003 `soft-foundry check`: pass.
- CHECK-004 `ruby -wc` on every library file, the executable, and the test file: no warnings.
- CHECK-005 `soft-foundry scan`: 0 errors.

## Failures
CHECK-002 fails by design.

## Evidence
`evidence/tests.log`, `evidence/red-at-1da10bc.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/scan-against-self.log`; hashes in `evidence/manifest.yml`.

Evidence generated for a different implementation commit is stale.
