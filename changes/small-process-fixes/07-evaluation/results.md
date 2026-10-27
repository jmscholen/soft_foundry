# Evaluation Results

Commit SHA: 3e356a192053aea57572f94afa3a15d7563ee647

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | AC-001 | pass | evidence/create.txt |
| EVAL-002 | AC-002 | pass | evidence/create.txt |
| EVAL-003 | AC-003, AC-012 | pass | evidence/refusals.txt |
| EVAL-004 | AC-004 | pass | evidence/refusals.txt |
| EVAL-005 | AC-010, AC-011, AC-012, AC-018, AC-019 | pass | evidence/summary.txt |
| EVAL-006 | AC-011, AC-012 | pass | evidence/summary.txt |

Size: full_route_sweep (whole repository; the CLI commands this change touches were swept in a scratch repository from `soft-foundry init`). `soft-foundry check` passed on the real repository.

## Not exercised
- Runner blocked-marking, parallel and auto-reopen, write-failure `warn:` (AC-005 to AC-008): needs a live phase-run session; covered only by the verification test suite.
- Protection-stated gate check (AC-014 to AC-016), content-scan guidance text (AC-009), parity rule text (AC-013), diff-level security and policy criteria (AC-017, AC-020): not user journeys; left to verification and review.
- Summary with completed phases, findings, a blocked phase or an open human decision (AC-010 populated case): only the empty-record summary was run; populated rendering is covered by tests only.
- The summary's `phase:` line showed `intake` for a fresh record; not judged.

## Failures
None.

## Accessibility observations
Non-TTY, NO_COLOR=1: no escape bytes in any transcript; outcomes are words; one fact per line with stable prefixes; errors state the fix. No interactive elements, so keyboard and focus checks do not apply.

## Re-run at current HEAD
All six journeys were re-run against the code at this commit (the REV-001 remediation changed only the parallel-run exit code in `lib/soft_foundry/cli.rb`) in a fresh scratch repository from `soft-foundry init`; transcripts in evidence/ replaced; all passed, zero ESC bytes. The parallel blocked exit code (REV-001) is not exercised live; it is covered by `test/phase_run_parallel_test.rb`.
