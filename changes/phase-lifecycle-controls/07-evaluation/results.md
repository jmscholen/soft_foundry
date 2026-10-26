# Evaluation Results

Commit SHA: 0af7da5ab3108db454fab80b351e13841e6575c6
Check size: `full_route_sweep` (no scope declared; whole repository). Provider keys unset. Real `exe/soft-foundry` of this checkout driven against throwaway repositories; a stub `claude` stood in for the coding shell.

## Journey outcomes
| Journey | Criteria | Result | Evidence |
| --- | --- | --- | --- |
| EVAL-001 | AC-001, AC-004, AC-005, AC-012, AC-013, AC-016 | pass | evidence/j1-reopen.txt |
| EVAL-002 | AC-002, AC-003, AC-010, AC-011, AC-014, AC-015 | pass (see EVAL-F1) | evidence/j2-gate-close.txt |
| EVAL-003 | AC-019 to AC-024, AC-028, AC-030 to AC-034 | pass | evidence/j3-parallel.txt, j3b, j3c, j3d |
| EVAL-004 | AC-035 to AC-043 | pass (see EVAL-F3) | evidence/j4-release.txt |
| EVAL-005 | AC-044, AC-048 | pass, UI by source and API only | evidence/j5-consumers.txt |
| EVAL-006 | AC-007, AC-008, AC-009, AC-049 | pass (see EVAL-F2) | evidence/j6-timeline-auto.txt |
| EVAL-007 | AC-025, AC-026, AC-027 | pass | evidence/j7-guard-a11y-docs.txt |
| EVAL-008 | AC-046, AC-047 | pass | evidence/a11y-captured-output.txt |
| EVAL-009 | AC-045, AC-050 | pass for what was in scope | evidence/j7-guard-a11y-docs.txt |

## Not exercised here
- AC-017 (failure injected between handoff resets and the metadata write), AC-029 (lock held more than 10 seconds), AC-018 (check against bad isolated_phases lists), AC-006 (old record without phase_reopenings) and AC-051 (full suite) are unit and verification territory; this phase did not rerun them. AC-045 is covered only by `soft-foundry eval` passing (18 passed, 1 skipped), not by reading the released-status case.
- The UI was not rendered in a browser. Keyboard operation, visible focus, and screen-reader announcement of the released view are unverified; only the page source (table caption, header cells, state words, tabindex on scroll regions) and the API were checked.
- docs/user/ is outside this skill's read set; AC-050's docs/user part is not assessed here.
- AC-003 and AC-010 etc. were run on scratch records whose phases were marked complete by a script, not by real sessions.

## Failures
No journey failed. The first parallel runs in evidence/j3-parallel.txt show gate failures ("no placeholders") because the stub shell then did not fill its templates; that was a defect in my stub, not the product, and j3b/j3c/j3d rerun with a corrected stub (evidence/j3-parallel.txt kept unedited apart from the placeholder word).

## Findings (none blocking)
- EVAL-F1 (minor, wording): AC-014 says a reopened phase's gate "fails". `soft-foundry gate <reopened phase>` and `gate all` print `pending ... SKIP` and exit 0, the same as for a never-started phase. The phase is not passed, and `change close` refuses (naming 14-judgment), so nothing can slip through, but the literal criterion wording is not met.
- EVAL-F2 (minor): plain-text `change status` shows the release line but not phase reopenings; they appear in the snapshot timeline (`change status --json`, UI). If AC-049 means the text form too, it is not met.
- EVAL-F3 (cosmetic): `ci` prints `released: c1: 2 open item(s): A, B` indented under `change c1 (released, not re-gated)` rather than at column 0 as AC-040 states.
- EVAL-F4 (observation, not new behavior): a parallel session that exits 0 but leaves its handoff `in_progress` with no commit_sha is reported `phase <id>: pass` (the gate does not fail an in-progress phase). Whether single `phase run` behaves the same was not compared.

## Accessibility observations
Command output: 0 non-ASCII bytes and 0 escape sequences across success and refusal output with NO_COLOR set and stdin closed; outcomes are words; every refusal names the next action; no prompts. UI source: items in a table with caption, column and row header cells; state as the words "open"/"discharged" and "Released"; scroll regions focusable. Rendered keyboard and screen-reader behavior not exercised (no browser).
