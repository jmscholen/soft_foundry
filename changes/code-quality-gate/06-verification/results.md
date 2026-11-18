# Verification Results

Commit SHA: 03a184bd1c611572f0ab14601406b250a9d1cc85 (tree fc6e9ccbe9ab62080b39d757645cb2d7c597bce5)

Check size: `full_at_verify` (no scope declared). All checks ran with the repository's own `lib/` (`ruby -Ilib exe/soft-foundry`). Provider keys and `SOFT_FOUNDRY_PHASE` were unset.

## Deterministic checks

| Check | Command | Result | Criteria |
| --- | --- | --- | --- |
| CHECK-001 | `ruby -Ilib -Itest test/code_quality_gate_test.rb` | pass: 27 runs, 218 assertions | AC-001 to AC-009, AC-011, AC-012 |
| CHECK-002 | `bundle exec rake test` (full suite) | pass: 978 runs, 7287 assertions, 0 failures, 0 errors, 0 skips | AC-010 |
| CHECK-003 | `soft-foundry check` | pass: 17 phases, 18 skills, no errors | AC-001 |
| CHECK-004 | `soft-foundry ci` | pass | AC-002, AC-010 |
| CHECK-005 | diff of existing tests, f508df2 to 03a184b | pass: edits match DEV-004 | AC-010 |

RED evidence: commit `c8d5a66` adds only `test/code_quality_gate_test.rb`. Application and control-plane code changed after it, in `4666f07`, across 38 files.

## Failures

None.

- The first full-suite run was stopped by this session's 10-minute background time limit. It had printed about 900 passing dots and no failures. The identical rerun took 1258 s and passed.
- The globally installed `soft-foundry` on this machine is older than this branch. `soft-foundry change status` there reports `06a-code-quality missing FAIL: handoff present` for this record. The worktree's own `lib/` reports `pending: not part of this record: it was created before the phase existed`. Every check here used the worktree's `lib/`. See VER-002.

## Evidence

Listed in `evidence/manifest.yml` with SHA-256 digests: the test logs, the `check` and `ci` output, the diff of existing tests and the RED commit's file list.

## Coverage notes

- AC-008 is covered only by structure. The test asserts that the quality gate carries the `remediation within cap` check. No test drives a third remediation round after a blocking quality finding (VER-001).
- AC-005, AC-009 and AC-011 are text criteria. The test file checks them by reading the skill, the documentation and the help output.

Evidence generated for a different implementation commit is stale.
