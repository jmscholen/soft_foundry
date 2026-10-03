# Verification Results

Commit SHA: 5d36e6f80e14c07928d3b5f1490403b17e01982e

## Deterministic checks
- CHECK-001 full suite with provider keys and Soft Foundry overrides unset: 388 runs, 2523 assertions, 0 failures, 0 errors, 0 skips.
- CHECK-002 the three new test files at the RED commit `0d69a4d`: 18 errors, and 5 errors with 1 failure in each of the other two. Retained as RED evidence.
- CHECK-003 the two remediation tests at their RED commit `ae60e88`: 1 error (server), 1 failure (snapshot). Retained as RED evidence.
- CHECK-004 `soft-foundry check`: pass.
- CHECK-005 `ruby -wc` on every library file, the executable, and the new test files, and `node --check` on `app.js`: no warnings.
- CHECK-006 `soft-foundry scan`: 0 errors, 5 warnings, all in earlier changes' records that quote attacks; none in this change's files at the time of the scan.

## Failures
CHECK-002 and CHECK-003 fail by design. No other failure.

## Evidence
`evidence/tests.log`, `evidence/red-at-0d69a4d.log`, `evidence/red-at-ae60e88.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/scan-against-self.log`; hashes in `evidence/manifest.yml`.

Evidence generated for a different implementation commit is stale.
