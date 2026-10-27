# Verification Results

Commit SHA: 030b28fb772fdc2cc610d255f3a5e09f35c50f01 (tree 896e09dcff2a710994b384298ff6f9c791452753)

This rerun follows the remediation of REV-001 and REV-002 (commit 030b28f: handoffs renamed before metadata, blank discharged_at refused), which changed lib/ and tests after the previous verify run. The evidence from 529e749 is stale and is preserved unedited in evidence/prior-run-529e749/; earlier runs are in evidence/prior-run-7342f98/ and evidence/prior-run-4c79227/.

## Deterministic checks
Check size: `full_at_verify` (no scope declared, whole repository). Full suite run with MAILTRAP_API_KEY, PERSONAL_SENDGRID_API_KEY, SOFT_FOUNDRY_PHASE and SOFT_FOUNDRY_PARALLEL unset.

| Check | Result |
| --- | --- |
| `rake test` | pass: 786 runs, 6042 assertions, 0 failures, 0 errors, 0 skips |
| `soft-foundry check` | pass (16 phases, 17 skills, no errors) |
| `soft-foundry eval` | pass (18 passed, 0 failed, 0 errors, 1 skipped: live case review-finds-planted-defect) |

## Failures
None at this commit.

## Red commit
053562b was confirmed to contain test/record_lock_test.rb (git cat-file). Other red commits named in the implementation handoff, and the remediation tests, were not individually re-confirmed.

## Evidence
evidence/rake-test.txt, evidence/check.txt, evidence/eval.txt; see evidence/manifest.yml.

Evidence generated for a different implementation commit is stale.
