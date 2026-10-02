# Verification Results

Commit SHA: 684fe7df390ac91fc3c854b68864af9c22c742d5

## Deterministic checks
- CHECK-001 full suite with provider keys and Soft Foundry overrides unset: 356 runs, 2218 assertions, 0 failures, 0 errors, 0 skips.
- CHECK-002 the three new test files at the RED commit `594de77`: 3, 15, and 5 of them failing (26 runs, 21 errors, 2 failures). Retained as the RED evidence CHECK-001 names.
- CHECK-003 `soft-foundry check`: pass.
- CHECK-004 `ruby -wc` on every library file, the executable, and the three new test files: no warnings.
- CHECK-005 `soft-foundry scan`: 0 errors, 5 warnings, all in records of earlier changes that quote attacks (`control-plane-scan`, `init-command`); none in this change.

## Failures
CHECK-002 fails by design. No other failure.

## Evidence
`evidence/tests.log`, `evidence/red-at-594de77.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/scan-against-self.log`; hashes in `evidence/manifest.yml`. The test log has timings and the seed removed so it is reproducible.

Evidence generated for a different implementation commit is stale.
