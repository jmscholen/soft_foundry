# Verification Results

Commit SHA: 5f8560f45a9651addb8eab99401e95b6c543ba16

## Deterministic checks
- CHECK-001 full suite with provider keys, Soft Foundry overrides, and `GITHUB_TOKEN` unset: 437 runs, 2889 assertions, 0 failures, 0 errors, 0 skips.
- CHECK-006 the flaky test, named at last: at the first GREEN commit (`5dfa6b4`) the suite failed once on `test_silent_connections_cannot_crowd_out_a_request`, whose request took 3.3 s against a fixed 2 s bound while the machine was loaded. This is the unattributed failure `changes/ui-processes` recorded. The test now asserts what it guards (answered before the read timeout) and the suite passed at `5f8560f`.
- CHECK-002 `test/updater_github_test.rb` at the RED commit `1da10bc`: 8 errors. Retained as RED evidence.
- CHECK-003 `soft-foundry check`: pass.
- CHECK-004 `ruby -wc` on every library file, the executable, and the two test files: no warnings.
- CHECK-005 `soft-foundry scan`: 0 errors.

## Failures
CHECK-002 fails by design.

## Evidence
`evidence/tests.log`, `evidence/red-at-1da10bc.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/scan-against-self.log`; hashes in `evidence/manifest.yml`.

Evidence generated for a different implementation commit is stale.
