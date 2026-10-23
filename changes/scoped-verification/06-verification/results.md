# Verification Results

Commit SHA: fb0bff73d47b9d0931cc34b6cf6f823e7d0e852a (tree 537d8d15a7e30f9008b1015e69432753809fabd0)

## Deterministic checks
- CHECK-001 full suite, provider keys unset: **run 1 FAILED**, 635 runs, 4393 assertions, 1 failure, 0 errors, 0 skips. The failure is `ProcessesTest#test_finds_a_real_running_process` (test/processes_test.rb:272, "Expected false to be truthy"). Output preserved in evidence/rake-test.txt.
- CHECK-001 rerun on the same unchanged tree: pass, 635 runs, 4396 assertions, 0 failures (evidence/rake-test-rerun.txt). The failing test also passes alone (1 run, 6 assertions).
- CHECK-002 `soft-foundry check`: pass (16 phases, 17 skills, no errors).
- CHECK-003 `soft-foundry ci`: pass.
- CHECK-004 harness evals: pass (18 passed, 0 failed, 0 errors, 1 skipped live case).
- Size: `soft-foundry change size --phase verify` reports full_at_verify (no scope declared; whole repository). Full suite recorded under `full_suite:` for the tree of HEAD fb0bff7. This records that a run named this tree; the gate does not prove it passed.
- Failing-test-first: red_commit 8287d58 for test/scoped_verification_test.rb is unchanged since the earlier run (57 runs, 26 failures, 25 errors there); not re-run this round.

## Failures
CHECK-001 run 1: ProcessesTest#test_finds_a_real_running_process failed. The test spawns `soft-foundry ui` and polls `ps` for it for 4 seconds; it did not appear within that window while the 467s suite was running. It passed on rerun and in isolation, so I read it as a timing flake under load, but I have not shown that. It is not related to the code changed in this change, which I did not diagnose further. I did not alter the test. The failure stays on record as result: fail.

## Evidence
evidence/rake-test.txt (failed run), evidence/rake-test-rerun.txt, evidence/check.txt, evidence/ci.txt, evidence/eval.txt, hashed in evidence/manifest.yml.
Not verified here: fixture quality (DEV-002), the single-record-per-branch sizing reading (IMPL-004), and the output wording and browser text of AC-019/AC-020 by hand.
