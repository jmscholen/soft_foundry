# Verification Results

Commit SHA: 8ecce2f7fa84ac190d96751ffa630572e6f4c3bd

Re-verification after remediation REM-001 (guard shell-command naming; phase run reruns a stale complete phase). The earlier evidence, bound to 776b640, was stale and has been replaced.

## Deterministic checks
- CHECK-001 full suite: 549 runs, 3734 assertions, 0 failures, 0 errors, 0 skips (pass).
- CHECK-002 same suite under LANG=C LC_ALL=C: 549 runs, 3734 assertions, 0 failures, 0 errors, 0 skips (pass).
- CHECK-003 soft-foundry check: 16 phases, 17 skills, no errors (pass).
- CHECK-004 soft-foundry eval: 12 passed, 0 failed, 0 errors, 1 skipped (pass; the skipped case is the live review case, which needs --live and is for evaluation).
- CHECK-005 soft-foundry ci: see below.

## Failures
None in the suite, check, or eval. Nothing was skipped except the live eval case above.

CHECK-005: a first ci run, made before this phase's records were rewritten, exited 2 only because the verify evidence was still bound to 776b640 (STALE: code changed since 776b64080523: guard.rb, phase_runner.rb, factory_readiness_test.rb, guard_test.rb). That is the staleness this re-verification resolves; ci was re-run after the records were rebound, and evidence/ci.txt is that second run.

## Evidence
See evidence/manifest.yml (sha256 per artifact). red_commit 26497a4 is the RED commit for test/factory_readiness_test.rb; the REM-001 RED commit d5940c2 touches the same file.

## Notes
- The runtime guard now permits naming test and exe paths in shell commands (REM-001), so soft-foundry ran as exe/soft-foundry directly. rake/bundler was still not used; the suite files were loaded directly with ruby (same minitest files).
- Each suite run takes about 8 minutes.
- AC-FR-015 (live eval on claude), the AC-FR-019 journey transcript, AC-FR-021 (user documentation) and accessibility are for evaluation/review, not covered here.

Evidence generated for a different implementation commit is stale.
