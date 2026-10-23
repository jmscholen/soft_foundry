# Verification Results

Commit SHA: 2294f861cb4d1d8d5ff0bc054f62a03c277f4763

## Deterministic checks
- CHECK-001 full suite, provider keys unset: pass. 632 runs, 4393 assertions, 0 failures, 0 errors, 0 skips.
- CHECK-002 `soft-foundry check`: pass (16 phases, 17 skills, no errors).
- CHECK-003 `soft-foundry ci`: pass.
- CHECK-004 harness evals: pass (18 passed, 0 failed, 0 errors, 1 skipped live case).
- Size: `soft-foundry change size` reports full_at_verify (no scope declared on this record, so the whole repository is sized full). The full suite is recorded under `full_suite:` against tree baf599520e439abcedd57f93262d7bd2ad80cf3a, the tree of HEAD 2294f86 (code paths clean; only this phase's evidence and handoff are uncommitted). This is a record of the run; the gate does not prove the suite passed.
- Failing-test-first: test/scoped_verification_test.rb at 8287d58 (RED) run in a temporary worktree: 57 runs, 26 failures, 25 errors. It is recorded as red_commit on CHECK-001.
- No change to soft_foundry.gemspec, Gemfile or Gemfile.lock since before the RED commit (no new dependency, AC-021).

## Failures
None in the checks run. Rerun at 2294f86, which adds the remediation of ATTACK-F-006 (an edit to git.branch after the evidence commit is a stale cause; one new test, 632 runs) on top of the size-slug fix and the remediation of ATTACK-F-001/002/004 and EVAL-F-001/002. The worktree holds uncommitted edits to this phase's evidence and handoff and the runner's metadata.yml update only; code paths are clean.
Not verified here: the quality of the fixtures corrected after RED (DEV-002) and the single-record-per-branch sizing reading (IMPL-004) are judgments for review. Behaviours listed under AC-017 to AC-020 are exercised by the test file, not independently by hand.
DEV-001 (control-plane files) was resolved by commit 73298e6, which added the policy, template fields, skill text, workflow rule, docs and six harness-eval cases; `check` and `ci` pass with them.

## Evidence
evidence/rake-test.txt, evidence/check.txt, evidence/ci.txt, evidence/eval.txt, hashed in evidence/manifest.yml.

Evidence generated for a different implementation commit is stale.
