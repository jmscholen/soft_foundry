# Verification Results

Commit SHA: 15e6d923296135a660f6648b635a61edf93433a2 (`Record gate-hardening implement`; the code is GREEN `7d33654` plus `c02528c`, RED `9a96f45`)

Check size computed by `soft-foundry change size --phase verify`: `full_at_verify` (no scope declared). Every command ran from this worktree with the branch's own code (`ruby -Ilib exe/soft-foundry`) under Ruby 3.3.1, with `ANTHROPIC_API_KEY`, `OPENAI_API_KEY`, `XAI_API_KEY`, `GEMINI_API_KEY`, `GOOGLE_API_KEY`, `SOFT_FOUNDRY_PHASE`, `SOFT_FOUNDRY_PARALLEL` and `SOFT_FOUNDRY_GUARD` unset (`env -u`), except CHECK-002, which sets the two AC-048 names.

## Deterministic checks

| Check | Command | Result | Evidence |
| --- | --- | --- | --- |
| CHECK-001 | `bundle exec rake test`, clean environment (the recorded full-suite run) | pass: 884 runs, 6585 assertions, 0 failures, 0 errors, 0 skips, 1007 s | `evidence/full-suite.txt` |
| CHECK-002 | `SOFT_FOUNDRY_PHASE=verify ANTHROPIC_API_KEY=x bundle exec rake test` (AC-048) | pass: 884 runs, 6585 assertions, 0 failures, 0 errors, 0 skips, 999 s | `evidence/suite-phase-env.txt` |
| CHECK-003 | `soft-foundry check` | pass: 16 phases, 17 skills, no errors | `evidence/check.txt` |
| CHECK-004 | `soft-foundry eval` | pass: 28 passed, 0 failed, 0 errors, 1 skipped (the live case, as always) | `evidence/eval.txt` |
| CHECK-005 | `soft-foundry ci` | pass: `ci passed`, exit 0; every closed record printed as `(closed, skipped)`; this record's sealed phases all PASS; 06-verification shown in progress at the time of the run | `evidence/ci.txt` |
| CHECK-006 | `git diff main --name-only -- changes/` excluding this record | pass: no file of any other record differs from `main` (merge base `3e5627d`), so the five closed-record files that do not parse are untouched | `evidence/closed-records-diff.txt` |
| CHECK-007 | `soft-foundry learn promote --dry-run` | pass: nothing to promote; 52 ids reported `already in .ai/rules/learned.md` (each confirmed present there), 12 skipped as below 0.80 | `evidence/learn-promote-dry-run.txt` |
| CHECK-008 | grep of the `lib/` diff against `main` for `net/http`, `open-uri`, `socket`, `SOFT_FOUNDRY_GUARD`, `enforcement.yml`; whole-tree grep for those requires | pass: see "AC-055" below | `evidence/diff-grep.txt` |
| CHECK-009 | RED commit shape: `git show --stat 9a96f45`, ancestry, and the five RED files run at `9a96f45` in a detached worktree | pass: 59 runs, 53 failures, 4 errors at RED (matches `05-implementation/log.md`); `9a96f45` is an ancestor of HEAD and `lib/` changed after it | `evidence/red-commit.txt` |
| CHECK-010 | `Gate::CHECKS` listed from the loaded library | pass: `structured files parse`, `commit lineage`, `test results recorded`, `criteria covered`, `evidence manifest verified`, `verdict recorded`, `fresh session recorded` are all entries | `evidence/gate-checks.txt` |

Every planned test method in `04-plan/testing.md`'s coverage table exists at HEAD under the listed name, in the five RED files or `test/gate_hardening_cli_test.rb`, with one exception noted under Failures. The full suite exercises them all; no per-criterion test was run in isolation beyond the RED-state run.

**AC-048.** The suite passes with a phase session's environment set (CHECK-002), the same 884 runs as the clean run.

**AC-050.** The dry run lists nothing to promote. The pre-change list is in `01-discovery`, outside this skill's read set; what this phase can state is that every id the dry run reports as already promoted is present in `.ai/rules/learned.md`, and that no id at or above 0.80 remains unpromoted.

**AC-052 (ci and closed-record clauses).** `ci` exits 0 with every record as it is on this branch; no other record's file differs from `main`. The timing clause (`gate all` against the pre-change gem) is the evaluation phase's, per the plan. The REQ-032 inspection of each new line is review's.

**AC-055 (search clause).** Two added lines in `lib/` mention `enforcement.yml`: a comment and `File.join(dir, "policies", "enforcement.yml")` in `ControlPlane#enforcement_mode`, the reader of the repository's own `.ai/policies/enforcement.yml` that REQ-014 requires. Neither `lib/soft_foundry/gate.rb`, `phase_seal.rb` nor `control_plane.rb` reads `SOFT_FOUNDRY_GUARD` or the machine-local override directory. No added line requires `net/http`, `open-uri` or `socket`; the three existing requires (`updater.rb`, `provider.rb`, `ui/server.rb`) are unchanged against `main`. The `--env SECRET=hunter2` clause is `phase_run_sealing_test#test_env_value_never_printed_by_sealing`, run inside CHECK-001; no evidence file here contains `hunter2`.

**Access-control parity.** `.ai/repository.yml` declares no `access_control`; every check records `protection: not_applicable`.

## Failures
None. Every check passed.

Observations that are not failures, carried as findings in `handoff.yml`:
- The plan's `harness_eval_test#test_lint_accepts_new_check_names` (AC-019) was never written; AC-019 rests on CHECK-003, CHECK-004 (ten gate cases naming the seven checks pass lint and run) and CHECK-010.
- AC-053 (attack cases) and AC-054 (residual-risk inspection) are named by no verification check; `criteria covered` warns at this phase by design, and the attack and judgment phases own them. AC-051's `docs/user/` clause and AC-052's timing clause are likewise the documentation and evaluation phases'.
- A first attempt at the two suite runs was started with the unset list mis-quoted (zsh does not word-split `$VAR`), so the environment was not cleared; it was stopped before finishing and its partial transcript overwritten by the runs recorded here, which print the exact `env -u` list in their first line.

## Evidence
`evidence/manifest.yml` lists every file under `evidence/` with its SHA-256. All transcripts were produced at HEAD `15e6d92` on 2026-10-29 between 06:11 and 06:46 UTC. The two suite transcripts are the complete `rake test` output (seed printed in each). None contains invisible, bidirectional, zero-width or control characters (scanned); no payload needed escaping.

Evidence generated for a different implementation commit is stale.
