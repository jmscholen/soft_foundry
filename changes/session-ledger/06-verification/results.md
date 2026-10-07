# Verification Results

Commit SHA: 93acd899cc20cb4c25bc7ffe38d374925c2920fa

## Deterministic checks
| Check | Result | Evidence |
| --- | --- | --- |
| CHECK-001 full suite, provider keys unset | pass: 466 runs, 3,109 assertions, 0 failures, 0 errors | evidence/tests.log |
| CHECK-002 new tests at the RED commit d278ecf | fail as intended: 91 runs, 14 failures, 18 errors | evidence/red-at-d278ecf.log |
| CHECK-003 soft-foundry check | pass | evidence/check.log |
| CHECK-004 ruby -wc and node --check | pass, no warnings | evidence/syntax-warnings.log |
| CHECK-005 soft-foundry ci against this repository | pass | evidence/ci-against-self.log |
| CHECK-006 soft-foundry scan | pass: 0 errors; 5 warnings, all in older records' quoted attacks | evidence/scan-against-self.log |
| CHECK-007 hook timing, 5,000 entries, real process | pass: 0.197 to 0.217 s per prompt, exit 0 each run | evidence/timing.log |
| CHECK-008 remediation REM-001 test (grok argument order) | pass, inside CHECK-001 | evidence/tests.log |
| CHECK-009 that test at the remediation RED commit 88eee99 | fail as intended: 7 runs, 1 failure | evidence/red-at-88eee99.log |

Acceptance criteria and the tests that cover them (all in CHECK-001):
- AC-001: GuardTest#test_grok_tool_names_get_the_same_decisions_as_claude_codes, #test_a_grok_payload_through_the_cli_is_refused_in_block_mode
- AC-002: SessionLedgerTest#test_one_entry_per_session_updated_in_place
- AC-003: #test_records_repository_branch_change_and_phase_from_the_folder
- AC-004: #test_prompts_are_masked_flattened_and_cut_and_the_files_are_private, #test_control_characters_are_removed_from_recorded_text
- AC-005: #test_session_log_is_silent_and_exits_zero_whatever_it_is_given, #test_a_corrupt_line_is_kept_and_does_not_stop_recording, #test_a_symlink_at_the_ledger_path_is_refused
- AC-006: #test_concurrent_writers_lose_no_entries
- AC-007: #test_grok_payloads_are_recorded_as_grok_whatever_the_shell_flag_says
- AC-008: #test_sessions_matches_every_word_and_filter_newest_first, #test_sessions_with_no_ledger_says_how_to_start_one, #test_status_word_says_whether_a_session_can_be_resumed
- AC-009: #test_resume_prints_the_newest_command_for_a_change_and_fails_when_there_is_none
- AC-010: #test_resume_commands_quote_the_folder_and_use_each_agents_form, #test_a_session_id_that_is_not_a_plain_identifier_is_never_recorded
- AC-011: SessionHooksTest (all seven tests)
- AC-012: PhaseRunnerTest#test_run_moves_current_phase_stamps_executed_by_and_gates_the_result, #test_a_codex_run_records_the_session_the_ledger_saw, #test_a_codex_run_with_no_recorded_session_leaves_session_id_null, CrossCliHooksTest#test_grok_runs_headless_with_a_chosen_session_id_and_the_claude_guard_hook
- AC-013: SnapshotTest#test_change_lists_its_recorded_sessions, UIAssetsTest#test_change_page_lists_recorded_sessions_as_text (rendering in a browser is evaluation's)
- AC-014: SessionLedgerTest#test_session_log_records_fast_with_a_large_ledger and CHECK-007
- AC-015: not a test; README, help, and schemas text are checked in evaluation

## Failures
None. CHECK-002's failures are the RED evidence, expected.

## Evidence
This is the second verification run; the first, at 98b55d1, was superseded by remediation REM-001. Every log in evidence/ was produced at 93acd899cc20cb4c25bc7ffe38d374925c2920fa (CHECK-002 and CHECK-009 at their RED commits, by design); hashes in evidence/manifest.yml. Limits: AC-012's Codex branch is exercised with a stubbed launcher and a seeded ledger, not a live Codex turn (its login has expired on this machine).
