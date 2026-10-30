# Verification Results

Commit SHA: dccdd8c7171d1c53d40d52cb5209cff1dd0c1ce4 (`Record gate-hardening remediate`; the code is GREEN `c664d12` after RED `a930c57`, on top of the earlier GREENs `7d33654`/`c02528c`, `c30af60`, `c5c20b4` and `39d7e4f`)

This is the fourth verification of this change. It reruns verification after the third remediation (`phase_reopenings` entry of 2026-10-30T01:42:57Z, EVAL-017 and EVAL-018); the previous run described `ff5c175`. Check size from `soft-foundry change size --phase verify`: `full_at_verify` (no scope declared). Every command ran from this worktree with the branch's own code (`ruby -Ilib exe/soft-foundry`) under Ruby 3.3.1 with `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `XAI_API_KEY`, `GEMINI_API_KEY`, `GOOGLE_API_KEY`, `SOFT_FOUNDRY_PHASE`, `SOFT_FOUNDRY_PARALLEL` and `SOFT_FOUNDRY_GUARD` unset, except CHECK-002, which sets the two AC-048 names. `git status` shows `lib/`, `test/` and `.ai/` clean against HEAD; the working tree also holds uncommitted evidence of the evaluation and attack phases, which this phase did not read or touch.

## Deterministic checks

| Check | Command | Result | Evidence |
| --- | --- | --- | --- |
| CHECK-001 | `bundle exec rake test`, clean environment, run alone | pass: 902 runs, 6653 assertions, 0 failures, 0 errors, 0 skips, 1002 s | `evidence/full-suite.txt` |
| CHECK-002 | `SOFT_FOUNDRY_PHASE=verify ANTHROPIC_API_KEY=x bundle exec rake test`, run alone (AC-048) | pass: 902 runs, 6653 assertions, 0 failures, 0 errors, 0 skips, 982 s | `evidence/suite-phase-env.txt` |
| CHECK-003 | `soft-foundry check` | pass: 16 phases, 17 skills, no errors, no warnings | `evidence/check.txt` |
| CHECK-004 | `soft-foundry eval` | pass: 28 passed, 0 failed, 0 errors, 1 skipped (the live case, as always) | `evidence/eval.txt` |
| CHECK-005 | `soft-foundry ci` | pass: `ci passed`, exit 0; 35 closed records printed `(closed, skipped)`; this record's phases 00 to 05 and 09 PASS; the only advisory is that the accessibility review has not run yet | `evidence/ci.txt` |
| CHECK-006 | `git diff main --name-only -- changes/` and `git status --short -- changes/`, excluding this record | pass: no file of any other record differs from `main` (merge base `3e5627d`) or is uncommitted | `evidence/closed-records-diff.txt` |
| CHECK-007 | `soft-foundry learn promote --dry-run` | pass: nothing to promote; 52 ids reported already promoted, each found in `.ai/rules/learned.md`; 12 skipped below 0.80 | `evidence/learn-promote-dry-run.txt` |
| CHECK-008 | grep of the `lib/` diff against `main`; whole-tree greps | pass: see AC-055 below | `evidence/diff-grep.txt` |
| CHECK-009 | RED commit shape and the RED files run at `9a96f45`, `4d7392a`, `d6c2748`, `cf7b76b`, `a930c57` in detached worktrees | pass: 59 runs, 53 failures, 4 errors at `9a96f45`; 6 runs, 6 failures at `4d7392a`; 7 runs, 1 failure at `d6c2748`; 8 runs, 8 failures at `cf7b76b`; 3 runs, 2 failures at `a930c57` (the third remediation file, CHECK-014); each is an ancestor of HEAD and `lib/` changed after it | `evidence/red-commit.txt`, `evidence/red-run-*.txt` |
| CHECK-010 | `Gate::CHECKS` listed from the loaded library | pass: 32 entries; the seven new check names all present | `evidence/gate-checks.txt` |
| CHECK-011 | every planned test method of `04-plan/testing.md` looked up at HEAD | **fail**: 51 planned, 35 in the planned file, 15 in another file, 1 missing (`harness_eval_test#test_lint_accepts_new_check_names`, AC-019) | `evidence/planned-tests.txt` |
| CHECK-012 | the five RED files, both remediation files and `git_hook_env_test.rb` run at HEAD in a detached worktree | pass: 77 runs, 375 assertions, 0 failures, 0 errors | `evidence/red-run-head.txt` |
| CHECK-013 | `test/remediation_gate_hardening_two_test.rb` (eight tests) | pass at HEAD (inside CHECK-012); fails 8 of 8 at RED `cf7b76b` | `evidence/red-run-head.txt`, `evidence/red-run-cf7b76b.txt` |
| CHECK-014 | `test/remediation_gate_hardening_three_test.rb` (three tests: EVAL-017, EVAL-018) run at RED `a930c57` and at HEAD | pass: 3 runs, 6 assertions, 0 failures at HEAD; 2 of 3 fail at `a930c57` (the third passes there, as the commit message's account of two failing tests says) | `evidence/red-run-three-a930c57.txt`, `evidence/red-run-three-dccdd8c.txt` |

**What changed since the previous verification at `ff5c175`.** `lib/soft_foundry/change_record.rb`, `gate.rb`, `git.rb` (a per-run memo of HEAD, branch tips and recorded commits; answers about a full commit hash cached for the life of the `Git` object; lineage failures end with a next action) and the new `test/remediation_gate_hardening_three_test.rb` (three tests). The suite grew from 899 to 902 runs, which is those three. They answer evaluation findings EVAL-017 (REQ-036, AC-052) and EVAL-018 (REQ-032). Whether `gate all` now meets the AC-052 timing bound is evaluation's measurement, not made here.

**AC-048.** The suite passes with a phase session's environment set (CHECK-002): the same 902 runs and 6653 assertions as the clean run.

**AC-050.** The dry run prints only skip lines. The pre-change list is in `01-discovery`, outside this skill's read set; what this phase states is that every id reported as already promoted is present in `.ai/rules/learned.md` and that no id at or above 0.80 remains unpromoted.

**AC-052 (ci and closed-record clauses).** `ci` exits 0; no other record's file differs from `main` or is uncommitted. The timing clause (`gate all` against the pre-change gem) belongs to evaluation.

**AC-055 (search clause).** Added `lib/` lines mentioning `enforcement.yml`: the comment and `File.join(dir, "policies", "enforcement.yml")` in `ControlPlane#enforcement_mode` (REQ-014), and the warning text and `File.exist?` test in `check.rb` for ATK-006. None reads `SOFT_FOUNDRY_GUARD` or the machine-local override; the "override" matches in `control_plane.rb` and `gate.rb` are path-group overrides and comments. No added line requires `net/http`, `open-uri` or `socket`; the three existing requires are unchanged against `main`. No evidence file here contains the `--env` probe value.

**Access-control parity.** `.ai/repository.yml` declares no `access_control`; every check records `protection: not_applicable`.

## Failures

**CHECK-011 fails: one planned test was never written.** `harness_eval_test#test_lint_accepts_new_check_names` (AC-019) exists nowhere under `test/`; every earlier verification reported the same (VER-002). AC-019 is covered by CHECK-003, CHECK-004 and CHECK-010. Nothing else failed. The isolation defect seen in the previous run (a suite run beside `eval`, `ci` or the worktree runs failing `harness_eval_test.rb:198`) did not recur because nothing ran beside either suite; it remains open as VER-003.

## Evidence
`evidence/manifest.yml` lists every file under `evidence/` with its SHA-256. All transcripts were produced at HEAD `dccdd8c7171d1c53d40d52cb5209cff1dd0c1ce4` between 2026-10-30 01:45Z and 02:25Z and replace the previous run's files of the same names. `red-run-three-*.txt` are new. None contains invisible, bidirectional, zero-width or control characters (scanned); no payload needed escaping. The helper scripts lived under `/tmp/sf-verify3`; CHECK-011's text is copied into its evidence file.

Evidence generated for a different implementation commit is stale.
