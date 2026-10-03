# Verification Results

Commit SHA: 3562625d953805f7ee47a9a0a3fc032d146ea22d

## Deterministic checks
- CHECK-001 full suite with provider keys and Soft Foundry overrides unset: 420 runs, 2818 assertions, 0 failures, 0 errors, 0 skips.
- CHECK-002 `soft-foundry check`: pass.
- CHECK-003 `ruby -wc` on every library file, the executable, and the test file, and `node --check` on `app.js`: no warnings.
- CHECK-004 `soft-foundry scan`: 0 errors; warnings only in earlier changes' records that quote attacks.
- CHECK-005 a count over the page's source: 34 uses of the four link makers; the only plain anchors with a repository address are the repository bar's two tabs and the makers themselves.

## Failures
None. There is no RED commit for this change; see `00-intake/assumptions.md`.

## Evidence
`evidence/tests.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/scan-against-self.log`, `evidence/references.log`; hashes in `evidence/manifest.yml`.

Evidence generated for a different implementation commit is stale.
