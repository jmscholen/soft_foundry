# Verification Results

Commit SHA: ab1723b2ace53d5cc8516924b716011fddc2ed67

## Deterministic checks
- CHECK-001 full suite with provider keys and Soft Foundry overrides unset: 393 runs, 2577 assertions, 0 failures, 0 errors, 0 skips.
- CHECK-002 `test/snapshot_test.rb` and `test/ui_assets_test.rb` at the RED commit `8ca41db`: two failures in each. Retained as RED evidence.
- CHECK-003 `soft-foundry check`: pass.
- CHECK-004 `ruby -wc` on every library file, the executable, and the two test files, and `node --check` on `app.js`: no warnings.
- CHECK-005 `soft-foundry scan`: 0 errors, 5 warnings, all in earlier changes' records that quote attacks.

## Failures
CHECK-002 fails by design. No other failure.

## Evidence
`evidence/tests.log`, `evidence/red-at-8ca41db.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/scan-against-self.log`; hashes in `evidence/manifest.yml`.

Evidence generated for a different implementation commit is stale.
