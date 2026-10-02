# Verification Results

Commit SHA: dd18466001ecc7246f8266643a154bcdc1ff0ff5

## Deterministic checks
- CHECK-001 full suite with provider keys and Soft Foundry overrides unset: 409 runs, 2702 assertions, 0 failures, 0 errors, 0 skips. Includes one test that starts a real server and finds it through the real `ps`.
- CHECK-002 the four test files at the RED commit `365382a`: 7 errors, 5 errors, 1 error, 1 failure. Retained as RED evidence.
- CHECK-006 the two changed test files at the remediation RED commit `79e48c2`: 3 failures and 4 errors, and 2 failures. Retained as RED evidence.
- CHECK-003 `soft-foundry check`: pass.
- CHECK-004 `ruby -wc` on every library file, the executable, and the four test files, and `node --check` on `app.js`: no warnings.
- CHECK-005 `soft-foundry scan`: 0 errors; warnings only in earlier changes' records that quote attacks.

## Failures
CHECK-002 and CHECK-006 fail by design.

One unexplained failure, stated rather than buried: the full suite was run four times at this commit. Three runs passed (409 runs, 0 failures). One run, the first inside the evidence script, exited non-zero; its log was overwritten by the next attempt before the failing test was read, and it did not recur in two further runs. The likeliest candidates are the tests that depend on timing or on the live process table (the real-process test, the silent-connection tests), on a machine that had five coding-shell sessions and several staged processes running. It is recorded as a possibly flaky test, not as a pass.

## Evidence
`evidence/tests.log`, `evidence/red-at-365382a.log`, `evidence/red-at-79e48c2.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/scan-against-self.log`; hashes in `evidence/manifest.yml`.

Not verified here: Linux. The suite ran on macOS; the `/proc` path and procps `ps` are exercised only when CI runs the real-process test on Ubuntu.

Evidence generated for a different implementation commit is stale.
