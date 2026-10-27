# Evaluation Results

Commit SHA: 821f1e8ffc2ad8de1fe70af87eabe048e1ea222f

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
