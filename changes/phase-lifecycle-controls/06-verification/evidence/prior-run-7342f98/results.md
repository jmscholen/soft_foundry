# Verification Results

Commit SHA: 7342f98395f31c9b541c505e2cb3a406711dacb4 (tree b0dd5fbac2c474a4455fe35f74c6ec4688ae93e1)

## Deterministic checks
Check size: `full_at_verify` (no scope declared, whole repository). Full suite run with provider keys unset.

| Check | Result |
| --- | --- |
| `rake test` | pass: 781 runs, 6004 assertions, 0 failures, 0 errors, 0 skips |
| `soft-foundry check` | pass (16 phases, 17 skills, no errors) |
| `soft-foundry eval` | pass (18 passed, 0 failed, 0 errors, 1 skipped) |

## Failures
None at this commit. The earlier verify run at 4c79227 failed with 2 test-fixture failures (isolated_phases fixtures); commit 7342f98 fixed the fixtures and this run is the rerun. The failed run is preserved unedited in evidence/prior-run-4c79227/.

## Red commit
053562b was confirmed to contain test/record_lock_test.rb. Other red commits named in the implementation handoff were not individually re-confirmed.

## Evidence
evidence/rake-test.txt, evidence/check.txt, evidence/eval.txt; see evidence/manifest.yml.

Evidence generated for a different implementation commit is stale.
