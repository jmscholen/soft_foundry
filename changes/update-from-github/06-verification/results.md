# Verification Results

Commit SHA: b7764e2687a9290cdbbec2901cc444e95756ff35

## Deterministic checks
- CHECK-001 full suite with provider keys, Soft Foundry overrides, and `GITHUB_TOKEN` unset: 437 runs, 2886 assertions, 0 failures, 0 errors, 0 skips.
- CHECK-002 the two test files at the RED commit `ae3e48b`: 12 errors and 3 failures; 2 failures. Retained as RED evidence.
- CHECK-003 `soft-foundry check`: pass (the profile edit is valid).
- CHECK-004 `ruby -wc` on every library file, the executable, and the two test files: no warnings.
- CHECK-005 `soft-foundry scan`: 0 errors.

## Failures
CHECK-002 fails by design. No other failure.

## Evidence
`evidence/tests.log`, `evidence/red-at-ae3e48b.log`, `evidence/check.log`, `evidence/syntax-warnings.log`, `evidence/scan-against-self.log`, `evidence/release-workflow.log`; hashes in `evidence/manifest.yml`.

Evidence generated for a different implementation commit is stale.
