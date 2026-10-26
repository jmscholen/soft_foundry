# Verification Results

Commit SHA: 529e749851af45073d32327857722660a72c3085 (tree 543e364149a5ab8b3e8873ff9eee4e50dbeb2e77)

This rerun follows remediation (ATK-001/002/003 fixes in lib/ with tests, committed in 529e749). The previous verify evidence (7342f98) is stale and is preserved unedited in evidence/prior-run-7342f98/; the earlier failed run is in evidence/prior-run-4c79227/.

## Deterministic checks
Check size: `full_at_verify` (no scope declared, whole repository). Full suite run with MAILTRAP_API_KEY, PERSONAL_SENDGRID_API_KEY, SOFT_FOUNDRY_PHASE and SOFT_FOUNDRY_PARALLEL unset.

| Check | Result |
| --- | --- |
| `rake test` | pass: 784 runs, 6030 assertions, 0 failures, 0 errors, 0 skips |
| `soft-foundry check` | pass (16 phases, 17 skills, no errors) |
| `soft-foundry eval` | pass (18 passed, 0 failed, 0 errors, 1 skipped) |

## Failures
None at this commit.

## Red commit
053562b was confirmed to contain test/record_lock_test.rb (git cat-file). Other red commits named in the implementation handoff were not individually re-confirmed.

## Evidence
evidence/rake-test.txt, evidence/check.txt, evidence/eval.txt; see evidence/manifest.yml.

Evidence generated for a different implementation commit is stale.
