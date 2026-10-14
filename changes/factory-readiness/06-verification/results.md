# Verification Results

Commit SHA: 378061e1c2ef1b0eb53623b415161d106a822f82

Re-verification after remediation REM-004 (the guard baselines its own configuration before each tool call, restores and refuses any change to it after a shell command; hooks install wires the post-call check; an undecidable refusal names no skill). Evidence bound to 4330cf4 was stale and has been replaced.

## Deterministic checks
- CHECK-001 full suite (default locale): 563 runs, 3833 assertions, 0 failures, 0 errors, 0 skips (pass).
- CHECK-002 same suite under LANG=C LC_ALL=C: 563 runs, 3833 assertions, 0 failures, 0 errors, 0 skips (pass).
- CHECK-003 soft-foundry check: 16 phases, 17 skills, no errors (pass).
- CHECK-004 soft-foundry eval: 12 passed, 0 failed, 0 errors, 1 skipped (pass; the skipped case is the live review case, which needs --live and is for evaluation).
- CHECK-005 soft-foundry ci: exit 2 (fail). The only failing lines are `evidence current` for evaluate and attack: STALE, code changed in lib/soft_foundry/cli.rb, guard.rb, hooks.rb and test/factory_readiness_test.rb since the commits those phases name. Verify itself is current at this commit's gate run.

## Failures
- CHECK-005 as above. Nothing else failed and nothing was skipped except the live eval case. Evaluate and attack stay stale until those phases rerun.
- The suites ran one after another, with check and eval run alongside the first suite. Neither suite failed; the intermittent live-case failure seen once in an earlier verification under concurrent load did not recur, but its cause was never investigated, so it is not shown to be fixed.

## Evidence
See evidence/manifest.yml (sha256 per artifact). red_commit 7f4db33 is the RED commit for test/factory_readiness_test.rb (REM-004), with GREEN d5805b3.

## Notes
- Each suite run takes about 8.5 minutes. rake/bundler was not used; the suite files were loaded directly with ruby (same minitest files). soft-foundry ran as ruby -Ilib exe/soft-foundry.
- AC-FR-015 (live eval on claude), the AC-FR-019 journey transcript, AC-FR-021 (user documentation) and accessibility are for evaluation/review, not covered here.

Evidence generated for a different implementation commit is stale.
