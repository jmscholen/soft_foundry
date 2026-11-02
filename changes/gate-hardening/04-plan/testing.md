# Test Plan

## Unit
Minitest, one new file per area plus additions to existing files, all in the RED commit:
- `test/phase_seal_test.rb` (new): sealing outcomes, staged paths, metadata transitions, idempotence, hook failure, dirty code, wrong phase marker, wrong branch, symlinked handoff, `branch_resolved`.
- `test/gate_checks_test.rb` (new): one test per new check per outcome (pass, fail, skip on a closed record), predecessor recorded, lineage against a stacked record's tip, `git:` non-mapping.
- `test/fixture_completion_test.rb` (new): a record completed by the shared fixture passes every gate, including the new checks, through judge.
- Additions: `test/phase_runner_test.rb` and `test/phase_run_parallel_test.rb` (sealing after a session; order; blocked exit), `test/cli_change_close_test.rb` (BLOCKED/REJECTED), `test/cli_change_new_options_test.rb` (equals form, twice), `test/cli_change_summary_test.rb` (malformed), `test/cli_phase_reopen_test.rb` (`started_at`), `test/cli_ps_test.rb` (parallel phases), `test/check_test.rb` (`forced_by_risk`), `test/cli_change_release_test.rb` (Unicode-blank `discharged_at`), `test/harness_eval_test.rb` (lint accepts the new check names; planted records are recorded), `test/gate_test.rb` (exit 3 through the CLI).

## Integration
- `soft-foundry ci` on this branch at the verification commit (AC-052).
- `soft-foundry eval` with the ten new gate cases (AC-051).
- The full suite with `SOFT_FOUNDRY_PHASE=verify ANTHROPIC_API_KEY=x` (AC-048) and with both unset (the recorded run).
- Evaluation journeys drive `phase seal` and `phase run` with a stub shell against a scratch repository (EVAL ids assigned by that phase), including the timing measurement for AC-052.

## Acceptance criteria coverage
| Criterion | Test layer | Planned test |
| --- | --- | --- |
| AC-001 | unit | `phase_seal_test#test_seal_commits_phase_and_metadata_and_advances` |
| AC-002 | unit | `phase_seal_test#test_gate_failure_commits_nothing` |
| AC-003 | unit | `phase_seal_test#test_refuses_incomplete_handoff` |
| AC-004 | unit | `phase_seal_test#test_refuses_dirty_code_paths` |
| AC-005 | unit | `phase_seal_test#test_leaves_unrelated_dirty_file_and_notes_it` |
| AC-006 | unit | `phase_seal_test#test_stages_only_the_phase_and_metadata` |
| AC-007 | unit | `phase_seal_test#test_judge_seal_sets_status_judged` |
| AC-008 | unit | `phase_seal_test#test_advances_past_skipped_phase` |
| AC-009 | unit | `phase_seal_test#test_already_sealed_is_idempotent` |
| AC-010 | unit | `phase_seal_test#test_hook_failure_leaves_rerunnable_state` |
| AC-011 | unit | `phase_runner_test#test_run_seals_passing_phase` |
| AC-012 | unit | `phase_runner_test#test_run_does_not_seal_in_progress_handoff` |
| AC-013 | unit | `phase_run_parallel_test#test_parallel_seals_passed_and_exits_2_on_blocked` |
| AC-014 | unit | `phase_run_parallel_test#test_parallel_seals_in_lifecycle_order` |
| AC-015 | unit | `phase_runner_test#test_prompt_says_runner_seals` |
| AC-016 | unit | `gate_checks_test#test_predecessor_must_be_recorded` |
| AC-017 | unit | `gate_checks_test#test_predecessor_steps_over_waived_phases` |
| AC-018 | unit | `gate_checks_test#test_new_checks_skip_on_closed_record`; integration `ci` |
| AC-019 | unit | `harness_eval_test#test_lint_accepts_new_check_names`; `check` |
| AC-020 | unit | `gate_checks_test#test_unparseable_specification_fails_and_cannot_seal` |
| AC-021 | unit | `gate_checks_test#test_sequence_manifest_fails_parse` |
| AC-022 | unit | `gate_checks_test#test_lineage_fails_on_older_commit` |
| AC-023 | unit | `gate_checks_test#test_lineage_fails_on_unreachable_commit` |
| AC-024 | unit | `gate_checks_test#test_lineage_measures_stacked_record_on_its_branch` |
| AC-025 | unit | `gate_checks_test#test_unacknowledged_fail_result_fails` |
| AC-026 | unit | `gate_checks_test#test_fail_result_named_in_finding_passes` |
| AC-027 | unit | `gate_checks_test#test_skipped_with_criteria_must_be_named` |
| AC-028 | unit | `gate_checks_test#test_uncovered_criteria_warn_at_verify` |
| AC-029 | unit | `gate_checks_test#test_uncovered_criteria_fail_at_judge` |
| AC-030 | unit | `gate_checks_test#test_criteria_set_aside_with_reason_pass_and_blank_reason_fails` |
| AC-031 | unit | `gate_checks_test#test_manifest_digest_mismatch_fails` |
| AC-032 | unit | `gate_checks_test#test_unlisted_evidence_file_warns` |
| AC-033 | unit | `gate_checks_test#test_manifest_path_outside_phase_fails` |
| AC-034 | unit | `gate_checks_test#test_verdict_blocked_is_recorded` |
| AC-035 | unit | `gate_checks_test#test_unfilled_verdict_fails` |
| AC-036 | unit | `gate_checks_test#test_fresh_session_required_in_block_mode` |
| AC-037 | unit | `gate_checks_test#test_fresh_session_skips_in_warn_mode` |
| AC-038 | unit | `gate_checks_test#test_fresh_session_ignores_machine_override` |
| AC-039 | unit | `gate_test#test_gate_on_pending_phase_exits_3_and_all_exits_0` |
| AC-040 | unit | `cli_change_close_test#test_refuses_blocked_without_force` |
| AC-041 | unit | `cli_change_close_test#test_closes_approved_with_residual_risk` |
| AC-042 | unit | `cli_change_new_options_test#test_equals_form_and_twice` |
| AC-043 | unit | `cli_change_summary_test#test_malformed_blocking_named` |
| AC-044 | unit | `phase_seal_test#test_branch_resolved_false_measures_head` |
| AC-045 | unit | `gate_checks_test#test_git_string_is_a_gate_line` |
| AC-046 | unit | `cli_phase_reopen_test#test_reopen_clears_started_at`; `cli_change_release_test#test_unicode_blank_discharged_at_is_open` |
| AC-047 | unit | `check_test#test_forced_by_risk_keys_checked` |
| AC-048 | integration | full suite with `SOFT_FOUNDRY_PHASE=verify` and a key set; recorded in `06-verification/evidence/` |
| AC-049 | unit | `phase_seal_test#test_refuses_symlinked_handoff`; `cli_change_summary_test#test_refuses_symlinked_handoff` |
| AC-050 | integration | `learn promote --dry-run` output recorded at verification |
| AC-051 | integration | README and `docs/user/` inspection at documentation; `eval` output recorded at verification |
| AC-052 | integration | `ci` output; `git diff main --stat` for the five files; timed `gate all` recorded at evaluation |
| AC-053 | attack | 08-attack cases ATTACK-001, -002, -003, -007, -009, -010 |
| AC-054 | judgment | 14-judgment/residual-risk.md inspection |
| AC-055 | integration | `grep` of the diff recorded at verification; `phase_run_parallel_test#test_env_value_never_printed_by_sealing` |

## Not covered and why
None left uncovered. AC-051's `docs/user/` clause and AC-054 are inspections performed by the documentation and judgment phases respectively, recorded in their results; the verification phase records the parts that are commands.
