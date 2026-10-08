# Verification Results

Commit SHA: 0370e02436d1b5a2a60fdaa057db67d19dabd158

## Deterministic checks
| Check | Result | Evidence |
| --- | --- | --- |
| CHECK-001 full suite, provider keys unset | pass: 478 runs, 0 failures, 0 errors | evidence/tests.log |
| CHECK-002 the new tests at the RED commit eb3ace3 | fail as intended: 10 runs, 7 failures, 2 errors | evidence/red-at-eb3ace3.log |
| CHECK-003 soft-foundry check | pass | evidence/check.log |
| CHECK-004 ruby -wc | pass, no warnings | evidence/syntax-warnings.log |
| CHECK-005 soft-foundry scan | pass: 0 errors; 5 warnings, all in older records' quoted attacks | evidence/scan-against-self.log |

Requirements to tests (CrossProviderReviewTest): REQ-XP-001 #test_review_and_judgment_declare_the_preference_and_check_lints_it; REQ-XP-002 #test_provider_names_are_normalized_from_the_handoff_or_the_shell; REQ-XP-003 #test_review_without_shell_picks_the_first_installed_other_provider_and_says_why, #test_remediation_counts_too, #test_with_no_other_provider_installed_it_warns_and_uses_what_there_is, #test_an_explicit_shell_wins_and_other_phases_keep_claude, #test_unknown_implementation_provider_keeps_claude_and_says_so; REQ-XP-004 #test_a_review_on_the_same_provider_is_advised; REQ-XP-005 #test_blocking_and_major_findings_must_name_the_failure_they_prevent, #test_templates_and_skill_text_carry_the_rule; REQ-XP-006 #test_templates_and_skill_text_carry_the_rule; REQ-XP-007 by evaluation and CHECK-003.

## Failures
None. CHECK-002's failures are the RED evidence.

## Evidence
Produced at 0370e02436d1b5a2a60fdaa057db67d19dabd158; hashes in evidence/manifest.yml.
