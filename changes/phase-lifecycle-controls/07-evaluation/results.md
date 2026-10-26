# Evaluation Results

Commit SHA: 6357775efd74e706a2955f0f73b00ad0d897f573
This evaluation replaces one bound to 0af7da5, which predates the remediation of ATK-001/002/003 (commit 529e749). Every journey was rerun at this commit; EVAL-010 is new. Code is unchanged since 529e749 (later commits are change records only).
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
| EVAL-010 | AC-012, AC-021, AC-022, AC-029, AC-035 | pass (see EVAL-F5, EVAL-F6) | evidence/j8-remediation.txt |

## Not exercised here
- AC-017 (failure injected between handoff resets and the metadata write), AC-029 (lock held more than 10 seconds), AC-018 (check against bad isolated_phases lists), AC-006 (old record without phase_reopenings) and AC-051 (full suite) are unit and verification territory; this phase did not rerun them. AC-045 is covered only by `soft-foundry eval` passing (18 passed, 1 skipped), not by reading the released-status case.
- The UI was not rendered in a browser. Keyboard operation, visible focus, and screen-reader announcement of the released view are unverified; only the page source (table caption, header cells, state words, tabindex on scroll regions) and the API were checked.
- docs/user/ is outside this skill's read set; AC-050's docs/user part is not assessed here.
- AC-003 and AC-010 etc. were run on scratch records whose phases were marked complete by a script, not by real sessions.

## Failures
No journey failed at this commit. The rerun of the parallel journeys passes both sessions in evidence/j3-parallel.txt; the earlier evaluation's `no placeholders` gate failures there came from its own stub and do not recur. Rerun differences from the earlier evidence are timestamps, SHAs, pids and ports, the `ps` listing, and one real change: a refused `phase reopen` now creates the git-ignored `.soft-foundry/locks/` directory (the record lock is taken before the state check), so `git status` in a scratch repository without the project's `.gitignore` shows `?? .soft-foundry/` after a refusal (j1-reopen.txt line 83). No tracked file changes.

## Findings (none blocking)
- EVAL-F1 (minor, wording): AC-014 says a reopened phase's gate "fails". `soft-foundry gate <reopened phase>` and `gate all` print `pending ... SKIP` and exit 0, the same as for a never-started phase. The phase is not passed, and `change close` refuses (naming 14-judgment), so nothing can slip through, but the literal criterion wording is not met.
- EVAL-F2 (minor): plain-text `change status` shows the release line but not phase reopenings; they appear in the snapshot timeline (`change status --json`, UI). If AC-049 means the text form too, it is not met.
- EVAL-F3 (cosmetic): `ci` prints `released: c1: 2 open item(s): A, B` indented under `change c1 (released, not re-gated)` rather than at column 0 as AC-040 states.
- EVAL-F4 (observation, not new behavior): a parallel session that exits 0 but leaves its handoff `in_progress` with no commit_sha is reported `phase <id>: pass` (the gate does not fail an in-progress phase). Whether single `phase run` behaves the same was not compared.

- EVAL-F5 (cosmetic): a release item id containing a zero-width space is refused, and the refusal prints the id back, zero-width character included, (in j8-remediation.txt line 14 the character is spelled <U+200B> so the content scan does not trip on the captured file; the raw output carried the character itself). The description and note fields refuse such characters outright.
- EVAL-F6 (observation): `--env` forms. `--env=NAME=V` is refused with the next action; a credential-shaped string given without a name, or as the name, is refused without being printed (0 occurrences); a name with a space is refused the same way. A SOFT_FOUNDRY_ name gets a different message that names the name; that is the intended reserved-prefix refusal.

## Remediation (EVAL-010)
Record lock: six simultaneous `phase reopen` runs produced one success, five `nothing to reset` refusals, and one `phase_reopenings` entry with a parseable metadata.yml. Six simultaneous `change release` runs produced one success and five `already released` refusals, and the record held only the winner's item. A release and a reopen started together ended released, with the reopen refused as released. Invisible characters (U+200B, U+202E, U+2028, U+2029, U+FEFF) are refused in `--reason`, a release item description and a discharge note, writing nothing; accented text is accepted. The race outcome in the release/reopen pair depends on which process takes the lock first; only the release-first order was observed, so the reopen-first order (reopen succeeds, release then refused for a pending judgment) was not exercised here.

## Accessibility observations
Command output: 0 of 32 lines of reopen, release, discharge and parallel-refusal output (evidence/a11y-captured-output.txt) and 0 of 103 lines in j1-reopen.txt contain a non-ASCII byte or an escape sequence (evidence/j9-a11y-counts.txt, counted with ruby; the inline count in j7-guard-a11y-docs.txt printed nothing because macOS grep has no -P, so the earlier evaluation's count claim rested on that blank). j4-release.txt carries the existing gate and ci check glyphs. Across success and refusal output with NO_COLOR set and stdin closed; outcomes are words; every refusal names the next action; no prompts. UI source: items in a table with caption, column and row header cells; state as the words "open"/"discharged" and "Released"; scroll regions focusable. Rendered keyboard and screen-reader behavior not exercised (no browser).
