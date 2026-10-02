# Verification Results

Commit SHA: 0d3a0436374b6af728209f039ed577a40c960d3a

## Deterministic checks
- CHECK-001 full suite with provider keys and Soft Foundry overrides unset: 407 runs, 2661 assertions, 0 failures, 0 errors, 0 skips. Includes one test that starts a real server and finds it through the real `ps`.
- CHECK-002 the four test files at the RED commit `365382a`: 7 errors, 5 errors, 1 error, 1 failure. Retained as RED evidence.
- CHECK-003 `soft-foundry check`: pass.
- CHECK-004 `ruby -wc` on every library file, the executable, and the four test files, and `node --check` on `app.js`: no warnings.
- CHECK-005 `soft-foundry scan`: 0 errors; warnings only in earlier changes' records that quote attacks.

## Failures
CHECK-002 fails by design. No other failure.

## Evidence
`evidence/tests.log`, `evidence/red-at-365382a.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/scan-against-self.log`; hashes in `evidence/manifest.yml`.

Not verified here: Linux. The suite ran on macOS; the `/proc` path and procps `ps` are exercised only when CI runs the real-process test on Ubuntu.

Evidence generated for a different implementation commit is stale.
