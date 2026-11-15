# Verification Results

Commit SHA: 9473ac341f075abcf3b65ac2723da9ed541cda15 (HEAD, `Record process-speed implement`; the code is identical to the implementation commit a37d580, the diff between them is the change record only). Tree 1bcdad4a6603f16cd582863dd8ed8360255282ef.

Size: `full_at_verify` (`soft-foundry change size --phase verify`: no scope declared). The full suite was run.

Environment: MAILTRAP_API_KEY, PERSONAL_SENDGRID_API_KEY and SOFT_FOUNDRY_PHASE unset; no provider API keys were set in the shell.

## Deterministic checks
| Check | Command | Result |
| --- | --- | --- |
| CHECK-001 | `bundle exec rake test` (full suite) | pass: 935 runs, 6885 assertions, 0 failures, 0 errors, 0 skips |
| CHECK-002 | `test/process_speed_test.rb -v` | pass: 26 runs, 162 assertions |
| CHECK-003 | `test/cli_process_speed_test.rb -v` | pass: 7 runs, 35 assertions |
| CHECK-004 | `soft-foundry check` | pass: 16 phases, 17 skills, no errors |
| CHECK-005 | `soft-foundry ci` | pass: harness eval 35 passed, 1 live case skipped; every record passes |
| CHECK-006 | gate on readme-workflow-visuals, old code against new code | pass: same phase outcomes; only three legacy skip lines added |
| CHECK-007 | new checks against `Gate::CHECKS` and eval gate cases | pass for CHECKS and eval; documentation not checked (VER-001) |
| CHECK-008 | skill text against REQ-013 | pass, with one wording note (VER-004) |

Acceptance criteria: every criterion AC-001 to AC-019 is named by at least one check. Person check PC-001 is not a criterion and was not exercised; it is carried as a release item.

RED/GREEN: CHECK-002 records red_commit 83cf46a (`test/process_speed_test.rb`, 431 lines added, nothing else) and CHECK-003 records f5c3032 (`test/cli_process_speed_test.rb`). A third RED commit, 62cf9a1, adds `test_specify_is_never_a_default_waiver` to `test/process_speed_test.rb`. I confirmed that each commit contains its test file and that `lib/` changed after it. I did not check out the RED commits to watch the tests fail.

## Failures
None. No check failed, errored or was skipped.

What was not verified:
- **VER-001:** the documentation part of AC-017 ("every new check has a documentation line") was not checked. Verification's `permissions.yml` does not grant read on `${DOCS}`, and the guard refused a shell command that named `docs/`. Documentation or review owns that comparison.
- **VER-002:** AC-012's `then` names specify among the default waivers. Under DEV-004 (maintainer decision) specify is never a default waiver, and the test asserts the narrowed behaviour. The criterion as worded is not met; the deviation is recorded. AC-012 is a should criterion.
- **VER-003:** AC-019 covers each new refusal, warning and advisory line. The test only covers the remediation-cap refusal. The other new messages were not checked under NO_COLOR with non-ASCII stripped. AC-019 is a should criterion.
- **VER-004:** REQ-013 says attack reports everything outside the must criteria as advisory. `adversarial-testing/SKILL.md` aims the attack at modified code and must criteria and sends out-of-change findings to follow-ups, but it does not say this outright. AC-016 is a should criterion.

## Evidence
`evidence/` holds the output of each command: `rake-test.txt`, `process-speed-tests.txt`, `check.txt`, `ci.txt`, `ac001-legacy-gate.txt`, `ac017-coverage.txt` and `ac016-skill-text.txt`. `evidence/manifest.yml` lists their SHA-256 digests.

Evidence generated for a different implementation commit is stale.
