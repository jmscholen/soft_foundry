# Verification Results

Commit SHA: 474926820805f938e6ce6b320630167a08569b4e

Re-verification after remediation REM-002 (guard follows cd, expands globs, resolves symlinks, owns its whole configuration directory; eval case files have a size cap). The earlier evidence, bound to 8ecce2f, was stale and has been replaced.

## Deterministic checks
- CHECK-001 full suite (default locale): 554 runs, 3760 assertions, 0 failures, 0 errors, 0 skips (pass).
- CHECK-002 same suite under LANG=C LC_ALL=C: 554 runs, 3760 assertions, 0 failures, 0 errors, 0 skips (pass, second run; see Failures).
- CHECK-003 soft-foundry check: 16 phases, 17 skills, no errors (pass).
- CHECK-004 soft-foundry eval: 12 passed, 0 failed, 0 errors, 1 skipped (pass; the skipped case is the live review case, which needs --live and is for evaluation).
- CHECK-005 soft-foundry ci: exit 2 (fail), because the evaluate and attack evidence are stale; the verify phase passes in that run. See below.

## Failures
- First C-locale run, made concurrently with the default-locale suite on the same machine, had 1 failure: HarnessEvalTest#test_a_live_case_passes_when_the_fresh_session_names_the_planted_defect (test/harness_eval_test.rb:194, expected exit 0, got 1). Preserved unedited in evidence/test-suite-c-locale-parallel-failed.txt. The test passed twice when run alone under the C locale, and the whole suite then passed under the C locale when run alone (evidence/test-suite-c-locale.txt). I did not investigate the cause; it appeared once under parallel load and did not reproduce, so it is recorded as an unexplained intermittent failure, not as resolved. Later phases should treat that test as potentially flaky under load.
- No other failures. Nothing was skipped except the live eval case above.

CHECK-005: a first ci run, made before this phase's records were rebound, exited 2 only because the verify, evaluate, and attack evidence were still bound to earlier commits (STALE: code changed in guard.rb, harness_eval.rb, factory_readiness_test.rb). The verify staleness is resolved by this re-verification; evaluate and attack evidence stay stale until those phases are rerun. evidence/ci.txt is the ci run made after the rebind and shows what remains.

## Evidence
See evidence/manifest.yml (sha256 per artifact). red_commit bce5413 is the RED commit for test/factory_readiness_test.rb (REM-002); earlier RED commits 26497a4 and d5940c2 touch the same file.

## Notes
- Each suite run takes about 8 minutes. rake/bundler was not used; the suite files were loaded directly with ruby (same minitest files). soft-foundry ran as ruby -Ilib exe/soft-foundry.
- AC-FR-015 (live eval on claude), the AC-FR-019 journey transcript, AC-FR-021 (user documentation) and accessibility are for evaluation/review, not covered here.

Evidence generated for a different implementation commit is stale.
