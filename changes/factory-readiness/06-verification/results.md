# Verification Results

Commit SHA: 4aca4144d484954e5b301d5421b9f1da585107c5

Re-verification after remediation REM-005 (an overlapping call keeps the first guard-config baseline until a check consumes it, a stale baseline is refreshed, the restore never writes through a symlink, and nothing to restore is quiet). Evidence bound to 378061e was stale and has been replaced.

## Deterministic checks
- CHECK-001 full suite (default locale): 566 runs, 3848 assertions, 0 failures, 0 errors, 0 skips (pass).
- CHECK-002 same suite under LANG=C LC_ALL=C: 566 runs, 3848 assertions, 0 failures, 0 errors, 0 skips (pass).
- CHECK-003 soft-foundry check: 16 phases, 17 skills, no errors (pass).
- CHECK-004 soft-foundry eval: 12 passed, 0 failed, 0 errors, 1 skipped (pass; the skipped case is the live review case, which needs --live and is for evaluation).
- CHECK-005 soft-foundry ci: exit 2 (fail). The only failing lines are `evidence current` for verify, evaluate and attack: STALE, code changed in lib/soft_foundry/cli.rb, guard.rb and test/factory_readiness_test.rb since the commits those phases name. Verify's own staleness is the old handoff SHA and clears once this handoff is committed.

## Failures
- CHECK-005 as above. Nothing else failed and nothing was skipped except the live eval case. Evaluate and attack stay stale until those phases rerun.
- The suites ran one after another (check and eval ran alongside the first). Neither failed; the intermittent live-case failure seen once in an earlier verification did not recur, but its cause was never investigated, so it is not shown to be fixed.

## Evidence
See evidence/manifest.yml (sha256 per artifact). red_commit 7533d7d is the RED commit for test/factory_readiness_test.rb (REM-005, confirmed to contain the added tests), with GREEN 6f6440f.

## Notes
- Each suite run takes about 8.5 minutes. rake/bundler was not used; the suite files were loaded directly with ruby (same minitest files). soft-foundry ran as ruby -Ilib exe/soft-foundry.
- AC-FR-015 (live eval on claude), the AC-FR-019 journey transcript, AC-FR-021 (user documentation) and accessibility are for evaluation/review, not covered here.
