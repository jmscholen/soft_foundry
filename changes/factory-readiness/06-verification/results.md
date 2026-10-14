# Verification Results

Commit SHA: 4330cf41cbb37e5afc7d00b275d1e1bfae77f8a1

Re-verification after remediation REM-003 (guard follows cd back to the root, expands braces, refuses what it cannot resolve instead of raising, guards Grep and Glob by path). The earlier evidence, bound to 4749268, was stale and has been replaced.

## Deterministic checks
- CHECK-001 full suite (default locale): 558 runs, 3796 assertions, 0 failures, 0 errors, 0 skips (pass).
- CHECK-002 same suite under LANG=C LC_ALL=C: 558 runs, 3796 assertions, 0 failures, 0 errors, 0 skips (pass).
- CHECK-003 soft-foundry check: 16 phases, 17 skills, no errors (pass).
- CHECK-004 soft-foundry eval: 12 passed, 0 failed, 0 errors, 1 skipped (pass; the skipped case is the live review case, which needs --live and is for evaluation).
- CHECK-005 soft-foundry ci: exit 2 (fail). The only failing lines are `evidence current` for verify (this phase's records still named the earlier commit when ci ran), evaluate and attack: STALE, code changed in lib/soft_foundry/cli.rb, guard.rb, hooks.rb and test/factory_readiness_test.rb. Evaluate and attack stay stale until those phases rerun.

## Failures
- CHECK-005 as above. Nothing else failed and nothing was skipped except the live eval case.
- The two suites ran one after another, not concurrently. The previous verification's one intermittent failure (harness_eval_test.rb:194, live-case test) was seen only when two suites ran at the same time; it did not occur in either run here, but its cause was never investigated, so it is not shown to be fixed. A first attempt at this run was cut off by a tool time limit during the C-locale suite; the default-locale result from that attempt (completed, exit 0) is the one recorded, and the C-locale suite was rerun in full.

## Evidence
See evidence/manifest.yml (sha256 per artifact). red_commit 78a1b35 is the RED commit for test/factory_readiness_test.rb (REM-003); earlier RED commits touch the same file.

## Notes
- Each suite run takes about 8.5 minutes. rake/bundler was not used; the suite files were loaded directly with ruby (same minitest files). soft-foundry ran as ruby -Ilib exe/soft-foundry.
- AC-FR-015 (live eval on claude), the AC-FR-019 journey transcript, AC-FR-021 (user documentation) and accessibility are for evaluation/review, not covered here.
