# Verification Results

Commit SHA: f94fba64204403ebade0d5b0b2ee8fe4b71aad82

## Deterministic checks
- CHECK-001 full suite, provider keys unset: pass. 630 runs, 4370 assertions, 0 failures, 0 errors, 0 skips.
- CHECK-002 `soft-foundry check`: pass (16 phases, 17 skills, no errors).
- CHECK-003 `soft-foundry ci`: pass.
- CHECK-004 harness evals: pass (18 passed, 0 failed, 0 errors, 1 skipped live case).
- Size: `soft-foundry change size` reports full_at_verify (no scope declared on this record, so the whole repository is sized full). The full suite is recorded under `full_suite:` against tree 8946fe016fc825cc9d03da8af73e85d196888745, the tree of the evidence commit. This is a record of the run; the gate does not prove the suite passed.
- Failing-test-first: test/scoped_verification_test.rb at 8287d58 (RED) run in a temporary worktree: 57 runs, 26 failures, 25 errors. It is recorded as red_commit on CHECK-001.
- No change to soft_foundry.gemspec, Gemfile or Gemfile.lock since before the RED commit (no new dependency, AC-021).

## Failures
None in the checks run. Rerun after remediation (ATTACK-F-001/002/004, EVAL-F-001/002): lib/ and the five new regression tests are covered by this run. The worktree holds uncommitted runner edits to this phase's handoff.yml and metadata.yml only; code paths are clean.
Not verified here: the quality of the fixtures corrected after RED (DEV-002) and the single-record-per-branch sizing reading (IMPL-004) are judgments for review. Behaviours listed under AC-017 to AC-020 are exercised by the test file, not independently by hand.
DEV-001 (control-plane files) was resolved by commit 73298e6, which added the policy, template fields, skill text, workflow rule, docs and six harness-eval cases; `check` and `ci` pass with them.

## Evidence
evidence/rake-test.txt, evidence/check.txt, evidence/ci.txt, evidence/eval.txt, hashed in evidence/manifest.yml.

Evidence generated for a different implementation commit is stale.
