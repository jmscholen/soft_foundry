# Verification Results

Commit SHA: 952808b9f07f1ddc712376123374fecfaebc7db8

## Deterministic checks
- CHECK-001 full suite with provider keys and Soft Foundry overrides unset: 419 runs, 2790 assertions, 0 failures, 0 errors, 0 skips. Run twice at this commit; both passed.
- CHECK-002 the five changed test files at the RED commit `83f631c`: 24 errors; 2 errors; 1 error; 3 failures and 2 errors; 1 failure. Retained as RED evidence.
- CHECK-003 `soft-foundry check`: pass.
- CHECK-004 `ruby -wc` on every library file, the executable, and the five test files, and `node --check` on `app.js`: no warnings.
- CHECK-005 `soft-foundry scan`: 0 errors; warnings only in earlier changes' records that quote attacks.

## Failures
CHECK-002 fails by design. No other failure.

Not caught by any of these: the two page faults found in the browser (see `05-implementation/log.md`). `node --check` passes a script whose function is shadowed by its own local variable, and nothing here runs the page.

## Evidence
`evidence/tests.log`, `evidence/red-at-83f631c.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/scan-against-self.log`; hashes in `evidence/manifest.yml`.

Evidence generated for a different implementation commit is stale.
