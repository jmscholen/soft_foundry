# Verification Results

Commit SHA: 4c79227f1433cfaf80b77d796c735aba08e5863e (tree 8e1eb90f9645106949003ad250ddb85019dd6986)

## Deterministic checks
Check size: `full_at_verify` (no scope declared, whole repository). Full suite run with provider keys unset.

| Check | Result |
| --- | --- |
| `rake test` | FAIL: 781 runs, 5999 assertions, 2 failures, 0 errors, 0 skips |
| `soft-foundry check` | pass (16 phases, 17 skills, no errors) |
| `soft-foundry eval` | pass (18 passed, 0 failed, 0 errors, 1 skipped) |

## Failures
Both failures are tests written in implementation (d2050f6) that assume the repository's real `.ai/workflow.yml` has no `isolated_phases` key. The later commit 4c79227 ("Apply ... owed control-plane") added `isolated_phases: [evaluate, attack]` to it (deviation D1 / IMPL-001).

1. `GuardSessionMarkerTest#test_a_parallel_marker_without_a_declared_list_is_a_violation` (test/guard_session_marker_test.rb:72): `with_parked_change(isolated: false)` only skips adding the key; it does not strip the copied real one, so the guard sees a declared list and reports no violation. Reproduced in isolation.
2. `PhaseRunParallelTest#test_a_workflow_without_isolated_phases_refuses_and_names_the_key` (test/phase_run_parallel_test.rb:153): expected a refusal, but `phase run evaluate attack --parallel` ran both phases, consistent with the same cause (the fixture inherits the real key). I did not rerun this one alone.

These are test-fixture defects, not confirmed product defects, and I did not edit tests. Implementation or remediation must make the fixtures strip the key, then verify must rerun. The feature code behaviour (refusal when the key is absent) is therefore not currently demonstrated by a passing test.

## Evidence
evidence/rake-test.txt, evidence/check.txt, evidence/eval.txt; see evidence/manifest.yml.
Red commits claimed: 053562b (slice 1 test file test/record_lock_test.rb) was taken from the implementation handoff and not individually re-confirmed here.

Evidence generated for a different implementation commit is stale.
