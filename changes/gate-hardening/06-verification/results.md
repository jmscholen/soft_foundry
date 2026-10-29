# Verification Results

Commit SHA: d8b621d6347231eb773243159833f7f870aeef93 (`Record gate-hardening remediate`; the code is GREEN `7d33654` plus `c02528c` after RED `9a96f45`, then the remediation's GREEN `c30af60` after RED `4d7392a` and GREEN `c5c20b4` after RED `d6c2748`)

This is the rerun of verification after remediation (`phase_reopenings` entry of 2026-10-29T11:35:26Z; the earlier verification was sealed at `303a48f` for commit `15e6d92`). Check size computed by `soft-foundry change size --phase verify`: `full_at_verify` (no scope declared). Every command ran from this worktree with the branch's own code (`ruby -Ilib exe/soft-foundry`) under Ruby 3.3.1, with `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `XAI_API_KEY`, `GEMINI_API_KEY`, `GOOGLE_API_KEY`, `SOFT_FOUNDRY_PHASE`, `SOFT_FOUNDRY_PARALLEL` and `SOFT_FOUNDRY_GUARD` unset (`env -u`, the exact list in the first line of each transcript), except CHECK-002, which sets the two AC-048 names.

## Deterministic checks

| Check | Command | Result | Evidence |
| --- | --- | --- | --- |
| CHECK-001 | `bundle exec rake test`, clean environment, run alone (the recorded full-suite run) | pass: 891 runs, 6619 assertions, 0 failures, 0 errors, 0 skips, 2928 s | `evidence/full-suite.txt` (first, concurrent run: `evidence/full-suite-run1.txt`, 1 failure, see below) |
| CHECK-002 | `SOFT_FOUNDRY_PHASE=verify ANTHROPIC_API_KEY=x bundle exec rake test`, run alone (AC-048) | pass: 891 runs, 6619 assertions, 0 failures, 0 errors, 0 skips, 1244 s | `evidence/suite-phase-env.txt` (first, concurrent run: `evidence/suite-phase-env-run1.txt`, 1 failure, see below) |
| CHECK-003 | `soft-foundry check` | pass: 16 phases, 17 skills, no errors | `evidence/check.txt` |
| CHECK-004 | `soft-foundry eval` | pass: 28 passed, 0 failed, 0 errors, 1 skipped (the live case, as always) | `evidence/eval.txt` |
| CHECK-005 | `soft-foundry ci` | pass: `ci passed`, exit 0; every closed record printed as `(closed, skipped)`; this record's sealed phases (00 to 05 and 09) all PASS; 06-verification shown in progress at the time of the run | `evidence/ci.txt` |
| CHECK-006 | `git diff main --name-only -- changes/` and `git status --short -- changes/`, excluding this record | pass: no file of any other record differs from `main` (merge base `3e5627d`) or is uncommitted, so the five closed-record files that do not parse are untouched | `evidence/closed-records-diff.txt` |
| CHECK-007 | `soft-foundry learn promote --dry-run` | pass: no promote line; 52 ids reported `already in .ai/rules/learned.md`, each confirmed present there; 12 skipped as below 0.80 | `evidence/learn-promote-dry-run.txt` |
| CHECK-008 | grep of the `lib/` diff against `main` for `net/http`, `open-uri`, `socket`, `SOFT_FOUNDRY_GUARD`, `enforcement.yml`; whole-tree greps | pass: see "AC-055" below | `evidence/diff-grep.txt` |
| CHECK-009 | RED commit shape: `git show --stat`, ancestry, and the RED files run at `9a96f45`, `4d7392a` and `d6c2748` in detached worktrees | pass: 59 runs, 53 failures, 4 errors at `9a96f45`; 6 runs, 6 failures at `4d7392a`; 7 runs, 1 failure at `d6c2748` (the one test it added); each RED commit is an ancestor of HEAD and `lib/` changed after it | `evidence/red-commit.txt`, `evidence/red-run-9a96f45.txt`, `evidence/red-run-4d7392a.txt`, `evidence/red-run-d6c2748.txt` |
| CHECK-010 | `Gate::CHECKS` listed from the loaded library | pass: 32 entries; `structured files parse`, `commit lineage`, `test results recorded`, `criteria covered`, `evidence manifest verified`, `verdict recorded`, `fresh session recorded` are all present | `evidence/gate-checks.txt` |
| CHECK-011 | every planned test method of `04-plan/testing.md`'s coverage table looked up at HEAD | **fail**: 51 planned, 35 in the planned file, 15 in another file, 1 missing (`harness_eval_test#test_lint_accepts_new_check_names`, AC-019) | `evidence/planned-tests.txt` |
| CHECK-012 | the five RED files, `test/remediation_gate_hardening_test.rb` and `test/git_hook_env_test.rb` run at HEAD in a detached worktree | pass: 69 runs, 347 assertions, 0 failures, 0 errors | `evidence/red-run-head.txt` |

**What changed since the sealed verification at `15e6d92`.** `lib/soft_foundry/change_record.rb`, `gate.rb` and `phase_seal.rb`, `test/phase_seal_test.rb` (one fixture reshaped) and the new `test/remediation_gate_hardening_test.rb` (seven tests). The suite grew from 884 to 891 runs, which is those seven. The remediation's tests are not in the plan's coverage table (they answer attack findings ATK-001, -002, -004, -005, -008, -009 and REM-004); they ran GREEN inside CHECK-001, CHECK-002 and CHECK-012, and RED at their commits inside CHECK-009.

**AC-048.** The suite passes with a phase session's environment set (CHECK-002, run alone): the same 891 runs and 6619 assertions as the clean run, 0 failures, 0 errors. Its first, concurrent run failed only the isolation-sensitive test described under Failures.

**AC-050.** The dry run prints only skip lines (nothing to promote). The pre-change list is in `01-discovery`, outside this skill's read set; what this phase can state is that every id the dry run reports as already promoted is present in `.ai/rules/learned.md`, and that no id at or above 0.80 remains unpromoted.

**AC-052 (ci and closed-record clauses).** `ci` exits 0 with every record as it is on this branch; no other record's file differs from `main` or is uncommitted. The timing clause (`gate all` against the pre-change gem) is the evaluation phase's, per the plan. The REQ-032 inspection of each new line is review's.

**AC-055 (search clause).** Two added lines in `lib/` mention `enforcement.yml`: a comment and `File.join(dir, "policies", "enforcement.yml")` in `ControlPlane#enforcement_mode`, the reader of the repository's own `.ai/policies/enforcement.yml` that REQ-014 requires; the remediation added none. Neither `gate.rb`, `phase_seal.rb`, `control_plane.rb` nor `change_record.rb` names `SOFT_FOUNDRY_GUARD` or the machine-local override directory. No added line requires `net/http`, `open-uri` or `socket`; the three existing requires (`updater.rb`, `provider.rb`, `ui/server.rb`) are unchanged against `main`. The `--env SECRET=hunter2` clause is `phase_run_sealing_test#test_env_value_never_printed_by_sealing`, run inside CHECK-001 and CHECK-002; no evidence file here contains `hunter2`.

**RED evidence.** Three RED commits are named in `tests.yml`: `9a96f45` (CHECK-001 and CHECK-002, the five original files), `4d7392a` (CHECK-012, the remediation file) and `d6c2748` (CHECK-009, the one test that commit added to the same file). Each was run at its own commit in CHECK-009 and failed there as the implementation log and the remediation summary say.

**Access-control parity.** `.ai/repository.yml` declares no `access_control`; every check records `protection: not_applicable`.

## Failures

**CHECK-011 fails: one planned test was never written.** `harness_eval_test#test_lint_accepts_new_check_names` (AC-019 in the plan's table) exists nowhere under `test/`; the earlier verification reported the same as VER-002. AC-019 is covered by CHECK-003 (`check` passes), CHECK-004 (the gate cases naming the seven checks pass lint and run) and CHECK-010 (the seven names are in `Gate::CHECKS`); the planned unit test is still owed or to be waived by review. Of the other 50 planned methods, 15 exist under a different file than planned (in `test/gate_hardening_cli_test.rb`, `test/phase_run_sealing_test.rb` and `test/phase_seal_test.rb`, the files the RED commit created instead of additions to existing files), under their planned names.

**The first run of each suite failed one test, and that failure is an isolation defect in the test, not a product failure.** Both first runs (`full-suite-run1.txt`, `suite-phase-env-run1.txt`) were started 20 seconds apart and overlapped each other, CHECK-004, CHECK-005 and CHECK-009's worktree runs; both failed only `HarnessEvalTest#test_a_live_case_passes_when_the_fresh_session_names_the_planted_defect` at `test/harness_eval_test.rb:198`, `assert_equal 0, scratch_dirs.size`, with `Actual: 1`. The assertions before it, including the live case's pass line, passed. `scratch_dirs` globs the system temp dir for `soft-foundry-eval-*`: it counts every harness-eval scratch repository on the machine, so any other process running an eval at that instant (another suite, `soft-foundry ci`, `soft-foundry eval`) makes it fail. Run alone the test passes (1 run, 8 assertions), and the full suite run alone passes (CHECK-001). This phase did not change the test; it is recorded as finding VER-003 for review (`.ai/rules/testing.md`: tests are deterministic and isolated). The recorded full-suite run is the one run alone.

Nothing else failed.

## Evidence
`evidence/manifest.yml` lists every file under `evidence/` with its SHA-256, including the two first-run transcripts. All transcripts were produced at HEAD `d8b621d` on 2026-10-29 between 20:21 and 21:57 UTC. The suite transcripts are the complete `rake test` output (seed printed in each). None contains invisible, bidirectional, zero-width or control characters (scanned, see `handoff.yml` notes); no payload needed escaping. The helper scripts for CHECK-009 and CHECK-011 lived under `/tmp`; CHECK-011's text is copied into its evidence file and CHECK-009's commands are described in the first lines of `red-commit.txt`. The evidence files of the sealed verification at `15e6d92` were overwritten by this run's files of the same names.

Evidence generated for a different implementation commit is stale.
