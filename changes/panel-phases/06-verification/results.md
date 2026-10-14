# Verification Results

Commit SHA: 4f3b2dadb445605f059bc1ff942d0de183d35044

## Deterministic checks
| Check | Result | Evidence |
| --- | --- | --- |
| CHECK-001 full suite, provider keys unset | pass: 515 runs, 3,419 assertions, 0 failures | evidence/tests.log |
| CHECK-002 the panel tests at the RED commit 553030c | fail as intended: 11 runs, 11 errors | evidence/red-at-553030c.log |
| CHECK-006 remediation tests (REM-001) | pass, inside CHECK-001; 11 failures at the RED commit 2ca6ff2 | evidence/tests.log, evidence/red-at-2ca6ff2.log |
| CHECK-007 Claude member's draft folder | pass, inside CHECK-001; failed at the RED commit f638ea4 (with one more failure there from a regex escape fixed in 2bdc19f) | evidence/tests.log, evidence/red-at-f638ea4.log |
| CHECK-009 REM-002 tests | pass, inside CHECK-001; 5 failures at the RED commit f69d6f2 | evidence/tests.log, evidence/red-at-f69d6f2.log |
| CHECK-010 REM-003 tests | pass, inside CHECK-001; 9 failures at the RED commit d7dca1a | evidence/tests.log, evidence/red-at-d7dca1a.log |
| CHECK-003 soft-foundry check | pass | evidence/check.log |
| CHECK-004 ruby -wc | pass, no warnings | evidence/syntax-warnings.log |
| CHECK-005 soft-foundry scan | pass: 0 errors; 5 warnings, all in older records' quoted attacks | evidence/scan-against-self.log |

Requirements to tests (PanelPhasesTest): REQ-PN-001 #test_members_are_named_by_shell_and_validated, #test_panels_are_refused_where_they_do_not_belong, #test_shell_args_reach_only_their_shell; REQ-PN-002, -003, -004, -005 #test_an_agreeing_panel_runs_every_stage_and_records_the_panel, #test_a_panel_that_never_agrees_is_split_and_parks_the_change, #test_a_forged_agree_line_does_not_count, #test_rewriting_earlier_argument_text_spoils_the_round; REQ-PN-006 #test_the_gate_checks_a_recorded_panel; REQ-PN-007 #test_the_guard_narrows_each_member_to_its_stage; REQ-PN-008 #test_a_single_provider_panel_is_advised; REQ-PN-009 #test_dry_run_prints_the_members_the_limit_and_the_commands; REQ-PN-010 #test_workflow_lists_panel_phases_and_check_lints_them and CHECK-003. `test_shell_args_reach_only_their_shell` has no separate RED commit (implementation deviation 2).

Fourth run, after remediations REM-001, REM-002, and REM-003; the runs at d1cf0d6, 2bdc19f, and 2a74680 are superseded.

## Failures
None. CHECK-002's errors are the RED evidence.

## Evidence
Produced at 4f3b2dadb445605f059bc1ff942d0de183d35044; hashes in evidence/manifest.yml.
