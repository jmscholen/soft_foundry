# Verification Results

Commit SHA: 50a45069a586f0ce37d9eb8d59da85ee37f6155d

Re-verification after remediation REM-006 (only a shell call records a guard-config baseline; hooks install and uninstall clear it). Evidence bound to 4aca414 was stale and has been replaced.

## Deterministic checks
- CHECK-001 full suite (default locale): 568 runs, 3861 assertions, 0 failures, 0 errors, 0 skips (pass).
- CHECK-002 same suite under LANG=C LC_ALL=C: 568 runs, 3861 assertions, 0 failures, 0 errors, 0 skips (pass).
- CHECK-003 soft-foundry check: 16 phases, 17 skills, no errors (pass).
- CHECK-004 soft-foundry eval: 12 passed, 0 failed, 0 errors, 1 skipped (pass; the skipped case is the live review case, which needs --live and is for evaluation).
- CHECK-005 soft-foundry ci: exit 2 (fail). The only failing lines are `evidence current` for verify, evaluate and attack: STALE, code changed in lib/soft_foundry/cli.rb, hooks.rb and test/factory_readiness_test.rb (attack also guard.rb) since the commits those phases name. Verify's own staleness is the old handoff SHA and clears once this handoff is committed.

## Failures
- CHECK-005 as above. Nothing else failed and nothing was skipped except the live eval case. Evaluate and attack stay stale until those phases rerun.
- The two suites ran one after another; check and eval ran alongside the first. No failures, so the earlier intermittent live-case failure did not recur, but its cause was never investigated and is not shown to be fixed.

## Evidence
See evidence/manifest.yml (sha256 per artifact). red_commit 9252178 is the RED commit for test/factory_readiness_test.rb (REM-006, its diff adds 33 lines to that file), with GREEN b0bb901.

## Notes
- Each suite run takes about 8.5 minutes. rake/bundler was not used; the suite files were loaded directly with ruby (same minitest files). soft-foundry ran as ruby -Ilib exe/soft-foundry.
- AC-FR-015 (live eval on claude), the AC-FR-019 journey transcript, AC-FR-021 (user documentation) and accessibility are for evaluation/review, not covered here.
